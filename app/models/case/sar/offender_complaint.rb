class Case::SAR::OffenderComplaint < Case::SAR::Offender

  include LinkableOriginalCase

  validates_presence_of :original_case

  class << self
    def type_abbreviation
      'OFFENDER_SAR_COMPLAINT'
    end
  end

  def offender_sar_complaint?
    true
  end

  def type_of_offender_sar?
    true
  end

  def offender_sar?
    false
  end
end
