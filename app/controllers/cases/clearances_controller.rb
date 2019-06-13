module Cases
  class ClearancesController < ApplicationController
    include SetupCase

    before_action :set_decorated_case, only: [
      :flag_for_clearance,
      :progress_for_clearance,
      :remove_clearance,
      :request_further_clearance,
      :unflag_for_clearance,
    ]

    # Should be create
    def flag_for_clearance
      authorize @case, :can_flag_for_clearance?

      CaseFlagForClearanceService.new(user: current_user,
                                      kase: @case,
                                      team: BusinessUnit.dacu_disclosure).call
      respond_to do |format|
        format.js { render 'cases/flag_for_clearance.js.erb' }
        format.html do
          redirect_to case_path(@case)
        end
      end
    end

    # Should be update
    def progress_for_clearance
      authorize @case

      @case.state_machine.progress_for_clearance!(
        acting_user: current_user,
        acting_team: @case.team_for_unassigned_user(current_user, :responder),
        target_team: @case.approver_assignments.first.team
      )

      flash[:notice] = t('notices.progress_for_clearance')
      redirect_to case_path(@case.id)
    end

    # Was request_further_clearance
    def request_further_clearance
      authorize @case

      service = RequestFurtherClearanceService.new(user: current_user, kase: @case)
      result = service.call

      if result == :ok
        flash[:notice] = 'Further clearance requested'
        redirect_to case_path(@case.id)
      else
        flash[:alert] = "Unable to request further clearance on case #{@case.number}"
        redirect_to case_path(@case.id)
      end
    end

    # Should be destroy
    def remove_clearance
      authorize @case
      # interstitial page for unflag_taken_on_case_for_clearance
    end

    def unflag_taken_on_case_for_clearance
      authorize @case, :unflag_for_clearance?
      service = CaseUnflagForClearanceService.new(user: current_user,
                                                  kase: @case,
                                                  team: BusinessUnit.dacu_disclosure,
                                                  message: params[:message])
      service.call
      if service.result == :ok
        flash[:notice] = "Clearance removed for this case."
        redirect_to case_path(@case)
      end
    end

    def unflag_for_clearance
      authorize @case

      CaseUnflagForClearanceService.new(
        user: current_user,
        kase: @case,
        team: BusinessUnit.dacu_disclosure,
        message: params[:message]
      ).call

      respond_to do |format|
        format.js { render 'cases/unflag_for_clearance.js.erb' }
        format.html do
          flash[:notice] = "Case has been de-escalated. #{ get_de_escalated_undo_link }".html_safe
          if @case.type_abbreviation == 'SAR'
            redirect_to incoming_cases_path
          else
            redirect_to case_path(@case)
          end
        end
      end
    end

    private

    def get_de_escalated_undo_link
      unlink_path = flag_for_clearance_case_path(id: @case.id)
      view_context.link_to(
        "Undo",
        unlink_path,
        { method: :patch, class: 'undo-de-escalate-link' }
      )
    end
  end
end
