class Case::SAR::OffenderComplaint < Case::SAR::Offender

  include LinkableOriginalCase

  class << self
    def type_abbreviation
      'OFFENDER_SAR_COMPLAINT'
    end
  end

  def offender_sar_complaint?
    true
  end

  def offender_sar?
    false
  end
end
