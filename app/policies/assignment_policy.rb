class AssignmentPolicy < ApplicationPolicy
  attr_reader :user, :assignment

  def initialize(user, assignment)
    @assignment = assignment
    super(user, assignment)
  end

  def can_create_for_team?
    clear_failed_checks
    check_team_is_not_already_assigned
  end

  def can_assign_to_new_team?
    clear_failed_checks
    check_assign_to_new_team_is_a_permitted_event
  end

  check :team_is_not_already_assigned do
    !assignment.case.with_teams?(assignment.team)
  end

  check :assign_to_new_team_is_a_permitted_event do
    assignment.case.state_machine.permitted_events(user.id).include?(:assign_to_new_team)
  end
end
