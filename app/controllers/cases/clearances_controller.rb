module Cases
  class ClearancesController < ApplicationController
    include SetupCase

    before_action :set_decorated_case

    # Interstitial page for unflag_taken_on_case_for_clearance
    def remove_clearance
      authorize @case
    end

    def progress_for_clearance
      authorize @case

      @case.state_machine.progress_for_clearance!(
        acting_user: current_user,
        acting_team: @case.team_for_unassigned_user(current_user, :responder),
        target_team: @case.approver_assignments.first.team,
      )

      flash[:notice] = t("notices.progress_for_clearance")
      redirect_to case_path(@case.id)
    end

    def flag_for_clearance
      authorize @case, :can_flag_for_clearance?

      service = CaseFlagForClearanceService.new(
        user: current_user,
        kase: @case,
        team: BusinessUnit.dacu_disclosure,
      )
      service.call

      respond_to do |format|
        format.js { render "flag_for_clearance" }
        format.html do
          redirect_to case_path(@case)
        end
      end
    end

    def request_further_clearance
      authorize @case

      service = RequestFurtherClearanceService.new(user: current_user, kase: @case)
      result = service.call

      if result == :ok
        flash[:notice] = "Further clearance requested"
      else
        flash[:alert] = "Unable to request further clearance on case #{@case.number}"
      end
      redirect_to case_path(@case.id)
    end

    def unflag_for_clearance
      authorize @case

      service = CaseUnflagForClearanceService.new(
        user: current_user,
        kase: @case,
        team: BusinessUnit.dacu_disclosure,
        message: params[:message],
      )
      service.call

      respond_to do |format|
        format.js { render "unflag_for_clearance" }
        format.html do
          flash[:notice] = "Case has been de-escalated. #{get_de_escalated_undo_link}".html_safe
          if @case.type_abbreviation == "SAR"
            redirect_to incoming_cases_path
          else
            redirect_to case_path(@case)
          end
        end
      end
    end

    def unflag_taken_on_case_for_clearance
      authorize @case, :unflag_for_clearance?

      service = CaseUnflagForClearanceService.new(
        user: current_user,
        kase: @case,
        team: BusinessUnit.dacu_disclosure,
        message: params[:message],
      )
      service.call

      if service.result == :ok
        flash[:notice] = "Clearance removed for this case."
        redirect_to case_path(@case)
      end
    end

  private

    def get_de_escalated_undo_link
      unlink_path = flag_for_clearance_case_path(id: @case.id)
      view_context.link_to(
        "Undo",
        unlink_path,
        { method: :patch, class: "undo-de-escalate-link" },
      )
    end
  end
end
