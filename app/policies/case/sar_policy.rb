class Case::SARPolicy < Case::BasePolicy

  def show?
    clear_failed_checks

    check(:user_is_a_manager_for_case) ||
      check(:user_is_a_responder_for_case) ||
      check(:responding_team_is_linked_to_case)
  end

  def new_case_link?
    clear_failed_checks
    check_can_trigger_event(:link_a_case) &&
      check_user_is_a_manager_for_case
  end

  def destroy_case_link?
    # If we can make a link, we can destroy a link
    new_case_link?
  end

  def can_close_case?
    clear_failed_checks
    self.case.drafting? &&
        user.responding_teams.include?(self.case.responding_team)
  end

  def can_add_attachment_to_flagged_and_unflagged_cases?
    false
  end

  check :responding_team_is_linked_to_case do
    self.case.linked_cases.detect do |kase|
      kase.responding_team.in? user.responding_teams
    end
  end

  check :user_is_a_responder_for_case do
    user.responding_teams.include?(self.case.responding_team)
  end
end
