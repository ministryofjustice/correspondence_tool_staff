class Case::SARPolicy < Case::BasePolicy

  def can_respond?
    false
    # clear_failed_checks
    # self.case.drafting? &&
    #     user.responding_teams.include?(self.case.responding_team)
  end

  def show?
    clear_failed_checks

    check(:user_is_a_manager_for_case) ||
      check(:user_is_a_responder_for_case) ||
      check(:responding_team_is_linked_to_case)
  end

  check :responding_team_is_linked_to_case do
    self.case.linked_cases.detect do |kase|
      kase.responding_team.in? user.responding_teams
    end
  end


  def new_case_link?
    clear_failed_checks
    check_can_trigger_event(:link_a_case) &&
      check_user_is_a_manager_for_case
    end
  def can_close_case?
    clear_failed_checks
    check_user_is_a_responder_for_case && check_case_is_in_attachable_state
  end
end
