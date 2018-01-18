class Case::FOI::StandardPolicy < Case::BasePolicy
  def can_request_further_clearance?
    clear_failed_checks

    check_case_can_be_escalated
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
