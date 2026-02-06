module Cases
  class SARExtensionsController < ApplicationController
    include SetupCase

    before_action :set_case, only: %i[new create destroy]

    def new
      authorize @case, :extend_sar_deadline?
      @case = CaseExtendSARDeadlineDecorator.decorate @case
    end

    def create
      authorize @case, :extend_sar_deadline?
      service = CaseExtendSARDeadlineService.new(
        user: current_user,
        kase: @case,
        extension_period: params[:case][:extension_period],
        reason: params[:case][:reason_for_extending],
      )
      service.call

      case service.result
      when :ok
        flash[:notice] = t(".success", case_type: @case.correspondence_type.shortname)
        redirect_to case_path(@case.id)
      when :validation_error
        @case = CaseExtendSARDeadlineDecorator.decorate @case
        @case.reason_for_extending = params[:case][:reason_for_extending]
        render :new
      else
        lash[:alert] = t(".error", case_type: @case.correspondence_type.shortname, case_number: @case.number)
        redirect_to case_path(@case.id)
      end
    end

    def destroy
      authorize @case, :remove_sar_deadline_extension?

      service = CaseRemoveSARDeadlineExtensionService.new(current_user, @case)
      service.call

      if service.result == :ok
        flash[:notice] = t(".success", case_type: @case.correspondence_type.shortname)
      else
        flash[:alert] = t(".error", case_type: @case.correspondence_type.shortname)
      end
      redirect_to case_path(@case.id)
    end
  end
end
