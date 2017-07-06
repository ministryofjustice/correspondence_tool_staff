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

  check :team_is_not_already_assigned do
    !assignment.case.with_teams?(assignment.team)
  end
end
