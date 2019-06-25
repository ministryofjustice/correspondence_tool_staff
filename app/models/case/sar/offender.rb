class Case::SAR::Offender < Case::Base
  class << self
    def type_abbreviation
      'OFFENDER'
    end
  end

  def self.searchable_fields_and_ranks
    super.merge(
        {
            subject_full_name:     'B'
        }
    )
  end

  jsonb_accessor :properties,
                 prison_number: :string,
                 subject_full_name: :string,
                 escalation_deadline: :date,
                 internal_deadline: :date,
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
                      :received_date

  has_paper_trail only: [
                    :name,
                    :email,
                    :postal_address,
                    :properties,
                    :received_date,
                  ]

  validates :third_party, inclusion: { in: [ true, false ], message: "Please choose yes or no" }
  validates :flag_for_disclosure_specialists, inclusion: { in: [ "yes", "no" ], message: "Please choose yes or no" }

  validates :name, presence: true, if: -> { third_party }
  validates :third_party_relationship, presence: true, if: -> { third_party }

  validates :date_of_birth, presence: true
  validates :message, presence: true

  validates_presence_of :email,          if: :send_by_email?
  validates_presence_of :postal_address, if: :send_by_post?

  validates :subject_full_name, presence: true
  validates :subject_type, presence: true
  validates :reply_method, presence: true
end
