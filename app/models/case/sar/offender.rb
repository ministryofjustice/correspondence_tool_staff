class Case::SAR::Offender < Case::SAR::Standard
  class << self
    def type_abbreviation
      'OFFENDER'
    end
  end

# Then I see an error message when I do not complete the following fields:

# full name of data subject

# date of birth

# what is relationship to MoJ

# flag as high profile case

# is the information being requested on someone else’s behalf

# where information should be sent

# what information is being requested

# when the SAR was received

  validates :date_of_birth_dd, presence: true
  validates :date_of_birth_mm, presence: true
  validates :date_of_birth_yyyy, presence: true
  validates_presence_of :name, :third_party_relationship, if: -> { third_party }

  validates :subject_type, presence: true

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
                  received_date_yyyy: :string,
                  reply_method: :string

  enum subject_type: {
    offender: 'offender',
    ex_offender: 'ex_offender',
  }
  enum reply_method: {
    send_by_post:  'send_by_post',
    send_by_email: 'send_by_email',
  }

end
