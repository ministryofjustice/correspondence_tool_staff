class Case::SAR::OffenderComplaint < Case::SAR::Offender
  class << self
    def type_abbreviation
      'OFFENDER_SAR_COMPLAINT'
    end
  end

  def offender_sar_complaint?
    true
  end

  def offender_sar?
    true
  end

  def offender_sar_standard?
    false
  end
end
