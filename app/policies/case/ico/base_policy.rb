class Case::ICO::BasePolicy < Case::BasePolicy
  def can_add_attachment_to_flagged_and_unflagged_cases?
    check_user_is_a_responder_for_case
  end

  def remove_clearance?
    false
  end

  def can_respond?
    clear_failed_checks
    check_can_trigger_event(:respond)
  end

  def can_set_outcome?
    clear_failed_checks
    user.in?(self.case.approving_team_users)
  end
end
