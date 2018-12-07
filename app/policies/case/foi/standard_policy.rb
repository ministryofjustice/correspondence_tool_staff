class Case::FOI::StandardPolicy < Case::BasePolicy

  class Scope
    attr_reader :user, :scope


    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      scopes = []
      if user.manager?
        scopes << ->(inner_scope) { inner_scope.all }
      end

      if user.responder?
        scopes << -> (inner_scope) { inner_scope.all }
      end

      if user.approver?
        scopes << ->(inner_scope) { inner_scope.all }
      end

      if scopes.present?
        final_scope = scopes.shift.call(scope)
        scopes.each do |scope_func|
          final_scope.or(scope_func.call(scope))
        end
        final_scope
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

  def upload_responses?
    clear_failed_checks
    check_user_is_in_current_team &&
      check_can_trigger_event(:add_responses)
  end

  def response_upload_and_approve?
    clear_failed_checks
    check_user_is_in_current_team &&
      check_can_trigger_event(:upload_response_and_approve)
  end

  def response_upload_for_redraft?
    clear_failed_checks
    check_user_is_in_current_team &&
      check_can_trigger_event(:upload_response_and_return_for_redraft)
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
