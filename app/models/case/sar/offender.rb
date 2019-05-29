class Case::SAR::Offender < Case::SAR::Standard
  class << self
    def type_abbreviation
      'OFFENDER'
    end
  end

  validates :number, presence: true
  validates :prison_number, presence: true

  jsonb_accessor :properties,
                 prison_number: :string

end
