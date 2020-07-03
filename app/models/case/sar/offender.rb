class Case::SAR::Offender < Case::Base
  class << self
    def type_abbreviation
      'OFFENDER_SAR'
    end

    def searchable_fields_and_ranks
      super.merge({
        subject_full_name: 'A',
        prison_number: 'B',
        previous_case_numbers: 'B',
        subject_aliases: 'B',
        other_subject_ids: 'B'
      })
    end
  end

  GOV_UK_DATE_FIELDS = %i[
    date_of_birth
    date_responded
    date_draft_compliant
    external_deadline
    received_date
  ].freeze

  include Steppable

  acts_as_gov_uk_date(*GOV_UK_DATE_FIELDS)

  jsonb_accessor :properties,
                 date_of_birth: :date,
                 escalation_deadline: :date,
                 external_deadline: :date,
                 flag_as_high_profile: :boolean,
                 internal_deadline: :date,
                 other_subject_ids: :string,
                 previous_case_numbers: :string,
                 prison_number: :string,
                 reply_method: :string,
                 subject_aliases: :string,
                 subject_full_name: :string,
                 subject_type: :string,
                 third_party_relationship: :string,
                 third_party: :boolean,
                 third_party_reference: :string,
                 third_party_company_name: :string,
                 late_team_id: :integer,
                 third_party_name: :string

  enum subject_type: {
    offender: 'offender',
    ex_offender: 'ex_offender',
    detainee: 'detainee',
    ex_detainee: 'ex_detainee',
    probation_service_user: 'probation_service_user',
  }

  enum reply_method: {
    send_by_post:  'send_by_post',
    send_by_email: 'send_by_email',
  }

  has_paper_trail only: [
    :name,
    :email,
    :postal_address,
    :properties,
    :received_date,
  ]

  has_many :data_requests, dependent: :destroy, foreign_key: :case_id
  accepts_nested_attributes_for :data_requests

  validates :third_party,          inclusion: { in: [true, false], message: "can't be blank" }
  validates :flag_as_high_profile, inclusion: { in: [true, false], message: "can't be blank" }

  # validates :third_party_name,         presence: true, if: -> { third_party }
  validates :third_party_relationship, presence: true, if: -> { third_party }

  validates :date_of_birth, presence: true

  validates_presence_of :email,          if: :send_by_email?
  validates_presence_of :postal_address, if: :send_by_post?

  validates :subject_full_name, presence: true
  validates :subject_type,      presence: true
  validates :reply_method,      presence: true

  validate :validate_date_of_birth
  validate :validate_received_date
  # validate :validate_third_party_names

  before_validation :reassign_gov_uk_dates
  before_save :set_subject

  before_save :use_subject_as_requester,
              if: -> { name.blank? }

  def validate_received_date
    super
  end

  def validate_date_of_birth
    if date_of_birth.present? && self.date_of_birth > Date.today
      errors.add(
        :date_of_birth,
        I18n.t('activerecord.errors.models.case.attributes.date_of_birth.not_in_future')
      )
    end
    errors[:date_of_birth].any?
  end

  def validate_third_party_names
    if third_party
      unless third_party_company_name.present? || third_party_name.present?
        errors.add(
            :third_party_name,
            I18n.t('activerecord.errors.models.case/offender_sar.attributes.third_party_name.blank')
        )
        errors.add(
            :third_party_company_name,
            I18n.t('activerecord.errors.models.case/offender_sar.attributes.third_party_company_name.blank')
        )
      end
    end
  end

  def default_managing_team
    BusinessUnit.find_by!(code: Settings.offender_sar_cases.default_managing_team)
  end

  def current_team_and_user_resolver
    CurrentTeamAndUser::SAR::Offender.new(self)
  end

  def offender_sar?
    true
  end

  def responding_team
    managing_team # both responding and managing - Branston are the only team who work on offender SARs
  end

  # This method is here to fix an issue with the gov_uk_date_fields
  # where the validation fails since the internal list of instance
  # variables lacks the date_of_birth field from the json properties
  #     NoMethodError: undefined method `valid?' for nil:NilClass
  #     ./app/state_machines/configurable_state_machine/machine.rb:256
  #
  # Only reassign dates that have not changed.
  def reassign_gov_uk_dates
    reassign = GOV_UK_DATE_FIELDS.map(&:to_s) - self.changed
    reassign.each do |field|
      self.send("#{field}=", self.read_attribute(field))
    end
  end

  # User can add data requests at any point in the workflow, but
  # the case state should not change
  def allow_waiting_for_data_state?
    self.current_state == 'data_to_be_requested'
  end

  # @todo: Should these steps be defined in 'Steppable' or the controller
  def steps
    %w[subject-details requester-details requested-info date-received].freeze
  end

  private

  def set_subject
    self.subject = subject_full_name
  end

  def use_subject_as_requester
    self.name = self.subject_full_name
  end
end
