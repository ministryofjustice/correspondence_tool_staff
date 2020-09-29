class Case::SAR::OffenderComplaint < Case::SAR::Offender
  class << self
    def type_abbreviation
      'OFFENDER_SAR_COMPLAINT'
    end
  end
end
