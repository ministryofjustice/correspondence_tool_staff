module Cases
  class AmendmentController < BaseController
    def request_amends
      authorize @case, :execute_request_amends?
      @next_step_info = NextStepInfo.new(@case, 'request-amends', current_user)
    end

    def execute_request_amends
      authorize @case
      CaseRequestAmendsService.new(
        user: current_user,
        kase: @case,
        message: params[:case][:request_amends_comment],
        is_compliant: params[:case][:draft_compliant] == 'yes').call
      if @case.sar?
        flash[:notice] = 'Information Officer has been notified a redraft is needed.'
      else
        flash[:notice] = 'You have requested amends to this case\'s response.'
      end
      redirect_to case_path(@case)
    end
  end
end
