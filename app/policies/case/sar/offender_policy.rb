class Case::SAR::OffenderPolicy < Case::SAR::StandardPolicy
  def create?
    clear_failed_checks
    check_can_trigger_event(:mark_as_waiting_for_data) &&
      check_user_is_a_manager_for_case
  end
end
