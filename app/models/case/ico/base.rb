class Case::ICO::Base < Case::Base

  jsonb_accessor :properties,
                 escalation_deadline: :date,
                 internal_deadline: :date,
                 external_deadline: :date

  class << self
    def type_abbreviation
      'ICO'
    end
  end

  def sent_by_email?
    true
  end

  def requires_flag_for_disclosure_specialists?
    false
  end
end
