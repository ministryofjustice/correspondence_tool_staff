class Case::SAR::OffenderPolicy < Case::SAR::StandardPolicy
  def create?
    clear_failed_checks
    check_user_is_a_manager
  end

  def mark_as_waiting_for_data?
    true
  end
end
