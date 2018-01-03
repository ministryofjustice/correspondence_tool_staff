class Case::SAR < Case::Base
  class << self
    def type_abbreviation
      'SAR'
    end
  end

  VALID_SUBJECT_TYPES = %w{ offender staff member_of_the_public }

  validates :subject_full_name, presence: true
  validates :third_party, inclusion: {in: [ true, false ], message: "can't be blank" }
  validates :subject_type, inclusion: { in: VALID_SUBJECT_TYPES, message: 'is not a valid subject type' }

end
