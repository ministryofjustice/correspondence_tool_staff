module Cases
  class AmendmentsController < ApplicationController
    include SetupCase

    before_action :set_decorated_case, only: %i[new create]

    # Was request_amends
    def new
      authorize @case, :execute_request_amends?

      @next_step_info = NextStepInfo.new(@case, "request-amends", current_user)
    end

    # Was execute_request_amends
    def create
      authorize @case, :execute_request_amends?

      service = CaseRequestAmendsService.new(
        user: current_user,
        kase: @case,
        message: params[:case][:request_amends_comment],
        is_compliant: params[:case][:draft_compliant] == "yes",
      )
      service.call

      flash[:notice] = if @case.sar?
                         "Information Officer has been notified a redraft is needed."
                       else
                         "You have requested amends to this case's response."
                       end

      redirect_to case_path(@case)
    end
  end
end
