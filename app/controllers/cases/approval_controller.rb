module Cases
  class ApprovalController < BaseController
    def approve
      authorize @case

      @case = @case.decorate
    end

    def execute_approve
      authorize @case, :approve?

      case_approval_service = CaseApprovalService.new(
        user: current_user,
        kase: @case,
        bypass_params: BypassParamsManager.new(params)
      )
      case_approval_service.call

      if case_approval_service.result == :ok
        current_team = CurrentTeamAndUserService.new(@case).team
        if @case.ico?
          flash[:notice] = t('notices.case/ico.case_cleared')
        else
          flash[:notice] = t('notices.case_cleared', team: current_team.name,
                             status: I18n.t("state.#{@case.current_state}").downcase)
        end
        redirect_to case_path(@case)
      else
        flash.now[:alert] = case_approval_service.error_message
        @case = @case.decorate
        render :approve
      end
    end

  end
end
