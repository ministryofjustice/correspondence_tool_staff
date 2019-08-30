class Case::SAR::OffenderPolicy < Case::SAR::StandardPolicy
  def transition?
    clear_failed_checks
    check_user_is_a_manager
  end

  def can_add_note_to_case?
    true
  end

  def can_record_data_request?
    true
  end
end
