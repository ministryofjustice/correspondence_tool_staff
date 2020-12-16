class Case::SAR::OffenderComplaintPolicy < Case::SAR::OffenderPolicy
  class Scope < Case::SARPolicy::Scope

    def correspondence_type
      CorrespondenceType.offender_sar_complaint
    end

  end

  def can_assign_to_team_member?
    clear_failed_checks
    check_can_trigger_event(:assign_to_team_member) && !self.case.assigned?
  end

end
