class Case::SAR::Offender < Case::Base
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
  validates :third_party, inclusion: {in: [ true, false ], message: "Please choose yes or no" }
  validates :flag_for_disclosure_specialists, inclusion: {in: [ true, false ], message: "Please choose yes or no" }
  validates_presence_of :name, :third_party_relationship, if: -> { third_party }

  validates :date_of_birth, presence: true
  validates :received_date, presence: true

  validates_presence_of :email,          if: :send_by_email?
  validates_presence_of :postal_address, if: :send_by_post?

  validates :subject_full_name, presence: true
  validates :subject_type, presence: true
  validates :reply_method, presence: true
  validates :subject, presence: true, length: { maximum: 100 }

  jsonb_accessor :properties,
                  prison_number: :string,
                  subject_full_name: :string,
                  subject_aliases: :string,
                  previous_case_numbers: :string,
                  other_subject_ids: :string,
                  external_deadline: :date,
                  date_of_birth: :date,
                  third_party: :boolean,
                  third_party_relationship: :string,
                  subject_type: :string,
                  received_date: :date,
                  reply_method: :string,
                  flag_for_disclosure_specialists: :boolean

  enum subject_type: {
    offender: 'offender',
    ex_offender: 'ex_offender',
  }
  enum reply_method: {
    send_by_post:  'send_by_post',
    send_by_email: 'send_by_email',
  }
  acts_as_gov_uk_date :date_of_birth,
                      :date_responded,
                      :date_draft_compliant,
                      :external_deadline,
                      :received_date,
                      validate_if: :received_in_acceptable_range?
end
