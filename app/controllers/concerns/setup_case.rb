module SetupCase
  extend ActiveSupport::Concern

  def set_case(case_id = params[:case_id])
    @case = Case::Base
      .includes(
        :message_transitions,
        assignments: [:team],
        approver_assignments: [:user],
      )
      .find(case_id)

    @case_transitions = @case.transitions.includes(:acting_user, :acting_team, :target_team).case_history.page(params[:page]).order(id: :desc)
    @correspondence_type_key = @case.type_abbreviation.downcase
  end

  def set_url
    @action_url = request.env["PATH_INFO"]
  end

  def set_permitted_events
    @permitted_events = @case.state_machine.permitted_events(current_user.id)
    @permitted_events ||= []
    @filtered_permitted_events = @permitted_events - %i[
      extend_for_pit
      request_further_clearance
      link_a_case
      remove_linked_case
      require_further_action
      require_further_action_to_responder_team
      require_further_action_unassigned
    ]
  end

  def set_decorated_case(case_id = params[:case_id])
    set_case(case_id)

    @case = @case.decorate
    @case_transitions = @case_transitions.decorate
  end

  def set_correspondence_type(type)
    @correspondence_type = CorrespondenceType.find_by_abbreviation(type.upcase)
    @correspondence_type_key = type
  end
  # rubocop:enable Rails/DynamicFindBy

  def set_assignments
    @assignments = []

    if @case.responding_team.in? current_user.responding_teams
      @assignments << @case.responder_assignment
    end

    if current_user.approving_team.in? @case.approving_teams
      @assignments << @case.assignments.for_team(current_user.approving_team.id).last
    end
  end
end
