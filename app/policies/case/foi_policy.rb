class Case::FOIPolicy < Case::BasePolicy
  def request_further_clearance?
    clear_failed_checks

    check_user_is_a_manager_for_case &&
      check_can_trigger_event(:request_further_clearance)
  end

  def can_request_further_clearance?
    clear_failed_checks

    !(check_case_is_assigned_to_dacu_disclosure &&
      check_within_escalation_deadline) &&
      check_case_is_not_assigned_to_press_or_private_office
  end

  private

  check :case_is_not_assigned_to_press_or_private_office do
    check_case_is_not_assigned_to_private_office ||
      check_case_is_not_assigned_to_press_office
  end
end
