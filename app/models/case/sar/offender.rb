class Case::SAR::Offender < Case::SAR::Standard
  class << self
    def type_abbreviation
      'OFFENDER'
    end
  end

  validates :number, presence: true
  validates :prison_number, presence: true

  jsonb_accessor :properties,
                  prison_number: :string,
                  subject_aliases: :string,
                  previous_case_numbers: :string,
                  other_subject_ids: :string,
                  date_of_birth_dd: :string,
                  date_of_birth_mm: :string,
                  date_of_birth_yyyy: :string,
                  subject_type: :string,
                  received_date_dd: :string,
                  received_date_mm: :string,
                  received_date_yyyy: :string

  enum subject_type: {
     offender: 'offender',
     non_offender: 'non_offender',
   }

end
