module CaseSetup
  extend ActiveSupport::Concern

  def set_case
    @case = Case::Base
      .includes(
        :message_transitions,
        transitions: [:acting_user, :acting_team, :target_team],
        assignments: [:team],
        approver_assignments: [:user]
      )
      .find(params[:case_id] || params[:id])

    @case_transitions = @case.transitions.case_history.order(id: :desc)
    @correspondence_type_key = @case.type_abbreviation.downcase
  end

  def set_url
    @action_url = request.env['PATH_INFO']
  end

  def set_permitted_events
    @permitted_events = @case.state_machine.permitted_events(current_user.id)
    @permitted_events ||= []
    @filtered_permitted_events = @permitted_events - [:extend_for_pit, :request_further_clearance, :link_a_case, :remove_linked_case]
  end

  def set_decorated_case
    set_case

    @case = @case.decorate
    @case_transitions = @case_transitions.decorate
  end
end
