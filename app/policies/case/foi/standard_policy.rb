class Case::FOI::StandardPolicy < Case::BasePolicy

  class Scope
    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    # FOIs are visible to anyone logged in to the system
    def resolve
      if @user.manager? || @user.responder? || @user.approver?
        @scope
      else
        @scope.none
      end
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

  def response_approve?
    clear_failed_checks
    check_case_requires_clearance &&
      check_user_is_in_current_team
  end

  def show?
    clear_failed_checks

    # FOIs should be viewable by anyone who is logged into the system.
    true
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
    !self.case.current_state.in?(%w{responded closed})
  end

  check :ds_flagged_case_can_be_escalated do
     self.case.outside_escalation_deadline? &&
      !self.case.current_state.in?(%w{responded closed})
  end
end
