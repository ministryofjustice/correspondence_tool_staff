module Cases
  class SarExtensionsController < ApplicationController
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
        flash[:notice] = t(".success")
        redirect_to case_path(@case.id)
      when :validation_error
        @case = CaseExtendSARDeadlineDecorator.decorate @case
        @case.reason_for_extending = params[:case][:reason_for_extending]
        render :new
      else
        flash[:alert] = t(".error", case_number: @case.number)
        redirect_to case_path(@case.id)
      end
    end

    def destroy
      authorize @case, :remove_sar_deadline_extension?

      service = CaseRemoveSARDeadlineExtensionService.new(current_user, @case)
      service.call

      if service.result == :ok
        flash[:notice] = t(".success")
      else
        flash[:alert] = t(".error")
      end
      redirect_to case_path(@case.id)
    end
  end
end
