module Cases
  class SarExtensionController < BaseController
    before_action :set_case, only: [:new, :create, :destroy]

    # Was extend_sar_deadline
    def new
      authorize @case

      @case = CaseExtendSARDeadlineDecorator.decorate @case
    end

    # Was execute_extend_sar_deadline
    def create
      authorize @case, :extend_sar_deadline?

      service = CaseExtendSARDeadlineService.new(
        user: current_user,
        kase: @case,
        extension_days: params[:case][:extension_period],
        reason: params[:case][:reason_for_extending]
      )
      service.call

      if service.result == :ok
        flash[:notice] = t('.success')
        redirect_to case_path(@case.id)
      elsif service.result == :validation_error
        @case = CaseExtendSARDeadlineDecorator.decorate @case
        @case.reason_for_extending = params[:case][:reason_for_extending]
        render :extend_sar_deadline
      else
        flash[:alert] = t('.error', case_number: @case.number)
        redirect_to case_path(@case.id)
      end
    end

    # Was remove_extend_sar_deadline
    def destroy
      authorize @case, :remove_sar_deadline_extension?

      service = CaseRemoveSARDeadlineExtensionService.new(
        current_user,
        @case
      )
      service.call

      if service.result == :ok
        flash[:notice] = t('.success')
        redirect_to case_path(@case.id)
      else
        flash[:alert] = t('.error')
        redirect_to case_path(@case.id)
      end
    end
  end
end
