class Case::SAR::OffenderComplaintPolicy < Case::SAR::OffenderPolicy
  class Scope < Case::SARPolicy::Scope

    def correspondence_type
      CorrespondenceType.offender_sar_complaint
    end

  end
end
