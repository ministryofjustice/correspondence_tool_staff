class Case::SAR::OffenderPolicy < Case::SAR::StandardPolicy
  def transition?
    clear_failed_checks
    check_user_can_manage_offender_sar
  end

  def edit?
    clear_failed_checks
    check_user_can_manage_offender_sar
  end

  def can_add_case?
    clear_failed_checks
    check_user_can_manage_offender_sar
  end

  def can_add_note_to_case?
    clear_failed_checks
    check_user_can_manage_offender_sar
  end

  def close?
    clear_failed_checks
    check_user_can_manage_offender_sar
  end

  def can_close_case?
    clear_failed_checks
    check_user_can_manage_offender_sar
  end

  def show?
    clear_failed_checks

    check_user_can_manage_offender_sar
  end

  def respond_and_close?
    clear_failed_checks
    check_user_can_manage_offender_sar
  end

  def can_record_data_request?
    clear_failed_checks
    check_can_trigger_event(:add_data_received)
  end

  def can_send_day_1_email?
    clear_failed_checks
    check_can_trigger_event(:send_day_1_email)
  end

  def can_send_acknowledgement_letter?
    clear_failed_checks
    check_user_can_manage_offender_sar
  end

  def can_send_dispatch_letter?
    clear_failed_checks
    check_user_can_manage_offender_sar
  end

  def can_validate_rejected_case?
    clear_failed_checks
    edit_case? && check_can_trigger_event(:validate_rejected_case)
  end

  def can_start_complaint?
    clear_failed_checks
    check_user_can_manage_offender_complaint
  end

  def extend_sar_deadline?
    clear_failed_checks
    check_user_can_manage_offender_sar && check_can_trigger_event(:extend_sar_deadline)
  end

  def remove_sar_deadline_extension?
    clear_failed_checks
    check_user_can_manage_offender_sar && check_can_trigger_event(:remove_sar_deadline_extension)
  end

  def can_upload_request_attachment?
    false
  end

  check :user_can_manage_offender_complaint do
    user.permitted_correspondence_types.include?(CorrespondenceType.offender_sar_complaint)
  end

  class Scope < Case::SARPolicy::Scope
    def correspondence_type
      CorrespondenceType.offender_sar
    end

    def resolve_responder_default
      @scope
    end

    def resolve_approver_default
      @scope
    end
  end
end
