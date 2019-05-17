module Cases
  class ResponseController
    def upload_responses
      authorize @case

      @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
      @case = @case.decorate
    end

    def execute_upload_responses
      authorize @case, :upload_responses?

      rus = ResponseUploaderService.new(
        kase: @case,
        current_user: current_user,
        action: 'upload',
        uploaded_files: params[:uploaded_files],
        upload_comment: params[:upload_comment],
        is_compliant: false,
        bypass_further_approval: false,
        bypass_message: nil
      )
      rus.upload!

      @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')

      case rus.result
      when :blank
        flash.now[:alert] = t('alerts.response_upload_blank?')
        render :upload_responses
      when :error
        flash.now[:alert] = t('alerts.response_upload_error')
        render :upload_responses
      when :ok
        flash[:notice] = t('notices.response_uploaded')
        set_permitted_events
        redirect_to case_path @case
      end
    end

    def upload_response_and_approve
      authorize @case

      @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
      @approval_action = 'approve'
      @case = @case.decorate
    end

    def execute_upload_response_and_approve
      authorize @case, :upload_response_and_approve?

      service = ResponseUploaderService.new(
        kase: @case,
        current_user: current_user,
        action: 'upload-approve',
        uploaded_files: params[:uploaded_files],
        upload_comment: params[:upload_comment],
        is_compliant: true,
        bypass_message: params.dig(:bypass_approval, :bypass_message),
        bypass_further_approval: params.dig(:bypass_approval, :press_office_approval_required) == 'false'
      )
      service.upload!

      @case = @case.decorate
      case service.result
      when :blank
        @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
        flash.now[:alert] = t('alerts.response_upload_blank?')
        render :upload_response_and_approve
      when :error
        @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
        flash.now[:alert] = t('alerts.response_upload_error')
        render :upload_response_and_approve
      when :ok
        flash[:notice] = t('notices.response_uploaded')
        set_permitted_events
        redirect_to case_path @case
      end
    end

    def upload_response_and_return_for_redraft
      authorize @case

      @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
      @approval_action = 'approve'
      @case = @case.decorate
    end

    def execute_upload_response_and_return_for_redraft
      authorize @case, :upload_response_and_return_for_redraft?

      rus = ResponseUploaderService.new(
        kase: @case,
        current_user: current_user,
        action: 'upload-redraft',
        uploaded_files: params[:uploaded_files],
        upload_comment: params[:upload_comment],
        is_compliant: params[:draft_compliant] == 'yes',
        bypass_message: nil,
        bypass_further_approval: false
      )
      rus.upload!

      @case = @case.decorate
      case rus.result
      when :blank
        @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
        flash.now[:alert] = t('alerts.response_upload_blank?')
        render :upload_response_and_return_for_redraft
      when :error
        @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
        flash.now[:alert] = t('alerts.response_upload_error')
        render :upload_response_and_return_for_redraft
      when :ok
        flash[:notice] = t('notices.response_uploaded')
        set_permitted_events
        redirect_to case_path @case
      end
    end

    def response_upload_for_redraft
      authorize @case

      @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
      @approval_action = 'redraft'
      @case = @case.decorate
    end
  end
end
