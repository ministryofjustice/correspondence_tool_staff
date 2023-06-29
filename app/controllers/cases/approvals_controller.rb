module Cases
  class ApprovalsController < ApplicationController
    include SetupCase

    before_action :set_case

    # Was approve
    def new
      authorize @case, :approve?

      @case = @case.decorate
    end

    # Was execute approve
    def create
      authorize @case, :approve?

      case_approval_service = CaseApprovalService.new(
        user: current_user,
        kase: @case,
        bypass_params: BypassParamsManager.new(params),
      )
      case_approval_service.call

      if case_approval_service.result == :ok
        current_team = CurrentTeamAndUserService.new(@case).team
        flash[:notice] = if @case.ico?
                           t("notices.case/ico.case_cleared")
                         else
                           t("notices.case_cleared", team: current_team.name,
                                                     status: I18n.t("state.#{@case.current_state}").downcase)
                         end
        redirect_to case_path(@case)
      else
        flash.now[:alert] = case_approval_service.error_message
        @case = @case.decorate
        render :new
      end
    end
  end
end
