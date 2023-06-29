module Cases
  class ResponsesController < ApplicationController
    include SetupCase

    before_action :set_action
    before_action :set_case, only: %i[new create]

    # @todo (@mseedat-moj): Move ACTION_SETTINGS to ResponseUploaderService
    # context is the current controller instance
    ACTION_SETTINGS = {
      upload_responses: {
        approval_action: nil,
        execution_action: "upload",
        policy: :upload_responses?,
        compliant: false,
        bypass_message: nil,
        bypass_further_approval: false,
      },
      upload_response_and_approve: {
        approval_action: "approve",
        execution_action: "upload-approve",
        policy: :upload_response_and_approve?,
        compliant: true,
        bypass_message: lambda { |context|
          context.params.dig(:bypass_approval, :bypass_message)
        },
        bypass_further_approval: lambda { |context|
          context.params.dig(
            :bypass_approval,
            :press_office_approval_required,
          ) == "false"
        },
      },
      upload_response_and_return_for_redraft: {
        approval_action: "approve",
        execution_action: "upload-redraft",
        policy: :upload_response_and_return_for_redraft?,
        compliant: lambda { |context|
          context.params[:draft_compliant] == "yes"
        },
        bypass_message: nil,
        bypass_further_approval: false,
      },
    }.freeze

    def new
      authorize @case, @settings[:policy]

      @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, "responses")
      @approval_action = @settings[:approval_action] # @todo: Unused value?
      @case = @case.decorate

      render @action
    end

    def create
      authorize @case, @settings[:policy]

      service = ResponseUploaderService.new(
        kase: @case,
        current_user:,
        action: @settings[:execution_action],
        uploaded_files: params[:uploaded_files],
        upload_comment: params[:upload_comment],
        is_compliant: as_proc(@settings[:compliant]),
        bypass_message: as_proc(@settings[:bypass_message]),
        bypass_further_approval: as_proc(@settings[:bypass_further_approval]),
      )
      service.upload!

      @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, "responses")
      @case = @case.decorate

      case service.result
      when :blank
        flash.now[:alert] = t("alerts.response_upload_blank?")
        render @action
      when :error
        flash.now[:alert] = t("alerts.response_upload_error")
        render @action
      when :ok
        flash[:notice] = t("notices.response_uploaded")
        set_permitted_events
        redirect_to case_path @case
      end
    end

  private

    def set_action
      @action = params[:response_action]&.downcase&.to_sym
      @settings = ACTION_SETTINGS[@action]

      unless ACTION_SETTINGS.key?(@action)
        raise ArgumentError, ":response_action is missing or unrecognised"
      end
    end

    def as_proc(val)
      val.respond_to?(:call) ? val.call(self) : val
    end
  end
end
