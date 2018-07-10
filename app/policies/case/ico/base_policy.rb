class Case::ICO::BasePolicy < Case::BasePolicy
  def can_add_attachment_to_flagged_and_unflagged_cases?
    check_user_is_a_responder_for_case
  end
end
