class Case::FOI::StandardPolicy < Case::BasePolicy
  class Scope < Case::BaseScopePolicy
    def correspondence_type
      CorrespondenceType.foi
    end

    def resolve_responder_default
      @scope
    end

    def resolve_approver_default
      @scope
    end

    def resolve_responder_open_cases_scope
      @scope.where(id: Assignment.team_restriction(@user.id, :responder))
    end

    def resolve_responder_closed_cases_scope
      @scope.where(id: Assignment.team_restriction(@user.id, :responder))
    end
  end

  def can_request_further_clearance?
    clear_failed_checks

    check_case_can_be_escalated
  end

  def execute_request_amends?
    clear_failed_checks

    (check_case_is_pending_press_office_clearance &&
        check_user_is_assigned_press_office_approver) ||
      (check_case_is_pending_private_office_clearance &&
          check_user_is_private_office_approver)
  end

  def can_send_back?
    clear_failed_checks
    check_can_trigger_event(:send_back)
  end

  def response_approve?
    clear_failed_checks
    check_case_requires_clearance &&
      check_user_is_in_current_team
  end

  def show?
    clear_failed_checks

    @user.permitted_correspondence_types.include? CorrespondenceType.foi
  end

  check :case_is_not_assigned_to_press_or_private_office do
    check_case_is_not_assigned_to_private_office ||
      check_case_is_not_assigned_to_press_office
  end

  check :case_can_be_escalated do
    if !self.case.flagged?
      check_unflagged_case_can_be_escalated
    elsif self.case.flagged_for_all?
      false
    elsif self.case.flagged_for_disclosure_specialist_clearance?
      check_ds_flagged_case_can_be_escalated
    else
      raise "Unable to determine whether case can be escalated"
    end
  end

  check :unflagged_case_can_be_escalated do
    !self.case.current_state.in?(%w[responded closed])
  end

  check :ds_flagged_case_can_be_escalated do
    self.case.outside_escalation_deadline? &&
      !self.case.current_state.in?(%w[responded closed])
  end
end
