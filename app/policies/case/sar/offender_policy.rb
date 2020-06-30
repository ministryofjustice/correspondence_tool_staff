class Case::SAR::OffenderPolicy < Case::SAR::StandardPolicy
  def transition?
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

  def can_send_acknowledgement_letter?
    clear_failed_checks
    check_user_can_manage_offender_sar
  end

  def can_send_dispatch_letter?
    clear_failed_checks
    check_user_can_manage_offender_sar
  end

  class Scope

    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      if @user.responder?
        case_ids = Assignment.with_teams(@user.responding_teams).pluck(:case_id)
        @scope.where(id: case_ids)
      else
        @scope.none
      end
    end

  end

end
