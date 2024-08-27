class Case::SAR::OffenderComplaintPolicy < Case::SAR::OffenderPolicy
  class Scope < Case::SAR::OffenderPolicy::Scope
    def correspondence_type
      CorrespondenceType.offender_sar_complaint
    end
  end

  def can_move_to_team_member?
    clear_failed_checks
    check_can_trigger_event(:move_to_team_member) && !self.case.assigned?
  end

  def can_be_reopened?
    clear_failed_checks
    check_can_trigger_event(:reopen) && self.case.closed?
  end
end
