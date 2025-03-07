class Case::SAR::StandardPolicy < Case::BasePolicy
  class Scope < Case::SARPolicy::Scope
  end

  def respond_and_close?
    clear_failed_checks
    user.responding_teams.include?(self.case.responding_team)
  end

  def show?
    clear_failed_checks

    check(:user_is_a_manager_for_case) ||
      check(:user_is_a_responder_for_case) ||
      check(:user_is_an_approver_for_case)
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
    user.responding_teams.include?(self.case.responding_team)
  end

  def can_add_attachment_to_flagged_and_unflagged_cases?
    false
  end

  def progress_for_clearance?
    clear_failed_checks
    check_can_trigger_event(:progress_for_clearance) &&
      check_user_is_a_responder_for_case
  end

  def execute_request_amends?
    clear_failed_checks

    check_can_trigger_event(:request_amends) &&
      check_user_is_an_approver_for_case
  end

  def can_request_further_clearance?
    !self.case.flagged?
  end

  def extend_sar_deadline?
    clear_failed_checks
    check_can_trigger_event(:extend_sar_deadline)
  end

  def remove_sar_deadline_extension?
    clear_failed_checks
    check_can_trigger_event(:remove_sar_deadline_extension)
  end

  def can_remove_attachment?
    clear_failed_checks
    check_can_trigger_event(:remove_response)
  end

  def upload_responses?
    clear_failed_checks
    check(:user_is_a_manager_for_case) &&
      check_can_trigger_event(:add_responses)
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
