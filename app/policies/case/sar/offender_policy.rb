class Case::SAR::OffenderPolicy < Case::SAR::StandardPolicy
  def create?
    clear_failed_checks
    check_user_is_a_manager
  end

  def mark_as_waiting_for_data?
    clear_failed_checks
    check_user_is_a_manager
  end

  def mark_as_ready_for_vetting?
    clear_failed_checks
    check_user_is_a_manager
  end

  def mark_as_vetting_in_progress?
    clear_failed_checks
    check_user_is_a_manager
  end

  def mark_as_ready_to_dispatch?
    clear_failed_checks
    check_user_is_a_manager
  end

  def mark_as_ready_to_close?
    clear_failed_checks
    check_user_is_a_manager
  end

  def mark_as_closed?
    clear_failed_checks
    check_user_is_a_manager
  end
end
