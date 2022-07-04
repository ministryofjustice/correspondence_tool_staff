#rubocop:disable Metrics/ClassLength
class Case::SAR::Offender < Case::Base

  belongs_to :reason_for_lateness, class_name: 'CategoryReference'

  class << self
    def type_abbreviation
      'OFFENDER_SAR'
    end

    def searchable_fields_and_ranks
      {
        subject_full_name: 'A',
        case_reference_number: 'B',
        date_of_birth: 'B',
        name: 'B',
        number: 'B',
        other_subject_ids: 'B',
        postal_address: 'B',
        previous_case_numbers: 'B',
        prison_number: 'B',
        requester_reference: 'B',
        subject: 'B',
        subject_address: 'B',
        subject_aliases: 'B',
        third_party_company_name: 'B',
        third_party_name: 'B',
      }
    end
  end

  DATA_SUBJECT_FOR_REQUESTEE_TYPE = 'data_subject'.freeze

  VETTING_IN_PROCESS_EVENT = 'mark_as_vetting_in_progress'.freeze
  READY_FOR_COPY_EVENT = 'mark_as_ready_to_copy'.freeze

  GOV_UK_DATE_FIELDS = %i[
    date_of_birth
    date_responded
    external_deadline
    request_dated
    partial_case_letter_sent_dated
    received_date
  ].freeze

  acts_as_gov_uk_date(*GOV_UK_DATE_FIELDS)

  jsonb_accessor :properties,
                 case_reference_number: :string,
                 date_of_birth: :date,
                 escalation_deadline: :date,
                 external_deadline: :date,
                 flag_as_high_profile: :boolean,
                 internal_deadline: :date,
                 other_subject_ids: :string,
                 previous_case_numbers: :string,
                 prison_number: :string,
                 recipient: :string,
                 subject_address: :string,
                 request_dated: :date,
                 request_method: :string,
                 requester_reference: :string,
                 subject_aliases: :string,
                 subject_full_name: :string,
                 subject_type: :string,
                 third_party_relationship: :string,
                 third_party: :boolean,
                 third_party_company_name: :string,
                 late_team_id: :integer,
                 third_party_name: :string,
                 number_final_pages: :integer,
                 number_exempt_pages: :integer,
                 is_partial_case: :boolean, 
                 partial_case_letter_sent_dated: :date, 
                 further_actions_required: :string

  attribute :number_final_pages, :integer, default: 0
  attribute :number_exempt_pages, :integer, default: 0

  enum subject_type: {
    offender: 'offender',
    ex_offender: 'ex_offender',
    detainee: 'detainee',
    ex_detainee: 'ex_detainee',
    probation_service_user: 'probation_service_user',
    ex_probation_service_user: 'ex_probation_service_user',
  }

  enum recipient: {
    subject_recipient:  'subject_recipient',
    requester_recipient: 'requester_recipient',
    third_party_recipient: 'third_party_recipient',
  }

  enum further_actions_required: {
    yes:  'yes',
    no: 'no',
    awaiting_response: 'awaiting_response',
  }
  
  enum request_method: {
    post: 'post',
    email: 'email',
    web_portal: 'web_portal',
    unknown: 'unknown',
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

  validates :third_party,          inclusion: { in: [true, false], message: "cannot be blank" }
  validates :flag_as_high_profile, inclusion: { in: [true, false], message: "cannot be blank" }
  validates :date_of_birth, presence: true

  validates_presence_of :subject_address
#  validates_presence_of :request_method, inclusion: { in: ['post','email','web_portal','unknown'], message: "cannot be blank" }

  validates :subject_full_name, presence: true
  validates :subject_type, presence: true
  validates :request_method, presence: true
  validates :recipient, presence: true
  
  validate :validate_date_of_birth
  validate :validate_received_date
  validate :validate_third_party_names
  validate :validate_recipient
  validate :validate_third_party_relationship
  validate :validate_third_party_address
  validate :validate_request_dated
  validates :number_final_pages,
            numericality: { only_integer: true, greater_than: -1,
                            message: 'must be a positive whole number' }
  validates :number_exempt_pages,
            numericality: { only_integer: true, greater_than: -1,
                            message: 'must be a positive whole number' }
  validate :validate_third_party_states_consistent
  validate :validate_partial_flags
  validate :validate_partial_case_letter_sent_dated

  before_validation :ensure_third_party_states_consistent
  before_validation :reassign_gov_uk_dates
  before_save :set_subject
  before_save :use_subject_as_requester,
              if: -> { name.blank? }

  def validate_third_party_states_consistent
    if self.third_party && self.recipient == 'third_party_recipient'
      errors.add(
        :recipient,
        I18n.t('activerecord.errors.models.case/sar/offender.attributes.recipient.third_party')
      )
    end
    errors[:recipient].any?
  end


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

  def validate_request_dated
    if request_dated.present? && self.request_dated > Date.today
      errors.add(
        :request_dated,
        I18n.t('activerecord.errors.models.case.attributes.request_dated.not_in_future')
      )
    end
    errors[:request_dated].any?
  end

  def validate_third_party_names
    if third_party && third_party_company_name.blank? && third_party_name.blank?
      errors.add(
          :third_party_name,
          I18n.t('activerecord.errors.models.case/sar/offender.attributes.third_party_name.blank')
      )
      errors.add(
          :third_party_company_name,
          I18n.t('activerecord.errors.models.case/sar/offender.attributes.third_party_company_name.blank')
      )
    end
    errors[:third_party_name].any? || errors[:third_party_company_name].any?
  end

  def validate_recipient
    if recipient == 'third_party_recipient' && third_party_company_name.blank? && third_party_name.blank?
        errors.add(
            :third_party_name,
            I18n.t('activerecord.errors.models.case/sar/offender.attributes.third_party_name.blank')
        )
        errors.add(
            :third_party_company_name,
            I18n.t('activerecord.errors.models.case/sar/offender.attributes.third_party_company_name.blank')
        )
    end
    errors[:third_party_name].any? || errors[:third_party_company_name].any?
  end

  def validate_third_party_relationship
    if (third_party || recipient == 'third_party_recipient') && third_party_relationship.blank?
        errors.add(
          :third_party_relationship,
          I18n.t('activerecord.errors.models.case/sar/offender.attributes.third_party_relationship.blank')
        )
    end
    errors[:third_party_relationship].any?
  end

  def validate_third_party_address
    if (third_party || recipient == 'third_party_recipient') && postal_address.blank?
        errors.add(
          :postal_address,
          I18n.t('activerecord.errors.models.case/sar/offender.attributes.third_party_address.blank')
        )
    end
    errors[:third_party_relationship].any?
  end

  def validate_partial_flags
    if (!is_partial_case && further_actions_required == 'yes')
      errors.add(
        :is_partial_case,
        I18n.t('activerecord.errors.models.case/sar/offender.attributes.is_partial_case.invalid')
      )
    end
  end

  def validate_partial_case_letter_sent_dated
    if is_partial_case? && partial_case_letter_sent_dated.present? && partial_case_letter_sent_dated > Date.today
      errors.add(
        :partial_case_letter_sent_dated,
        I18n.t('activerecord.errors.models.case.attributes.partial_case_letter_sent_dated.not_in_future')
      )
    end
    errors[:partial_case_letter_sent_dated].any?
  end

  def default_managing_team
    BusinessUnit.find_by!(code: Settings.offender_sar_cases.default_managing_team)
  end

  def current_team_and_user_resolver
    CurrentTeamAndUser::SAR::Offender.new(self)
  end

  def type_of_offender_sar?
    true
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

  # DATA MAPPING FIELDS - NAMING THE CONCEPTS
  def subject_name
    subject_full_name
  end

  def third_party_address
    postal_address
  end


  def requester_name
    third_party ? third_party_name : subject_name
  end

  def requester_address
    third_party ? third_party_address : subject_address
  end

  def recipient_name
    return subject_name if subject_recipient?
    third_party_name.presence || ''
  end

  def recipient_address
    (!subject_recipient?) ? postal_address : subject_address
  end

  def page_count
    DataRequest.where(case_id: self.id).sum(:cached_num_pages)
  end

  def requester_type
    self.third_party? ? self.third_party_relationship : 'data_subject'
  end

  def data_requests_completed?
    data_requests = DataRequest.where(case_id: self.id)
    unless data_requests.empty?
      data_requests.all? { |data_item| data_item.completed }
    else
      false
    end
  end

  def first_prison_number
    return '' unless prison_number.present?
    prison_number.gsub(/[,]/, ' ').split(' ').first.upcase
  end

  def number_of_days_for_vetting
    # Get the start date and end date for the vetting process
    start_date_for_vetting = nil
    end_date_for_vetting = nil
    self.transitions.each do | transition|
      if transition.event == VETTING_IN_PROCESS_EVENT
        start_date_for_vetting = transition.created_at.to_date
      end
      if transition.event == READY_FOR_COPY_EVENT
        end_date_for_vetting = transition.created_at.to_date
      end
    end
    end_date_for_vetting = end_date_for_vetting || Date.today
    # Calculate the days taken for vetting process
    days = nil
    if start_date_for_vetting
      days = start_date_for_vetting.business_days_until(end_date_for_vetting, true) 
    end
    days
  end

  def user_dealing_with_vetting
    user_for_vetting = nil
    self.transitions.each do | transition|
      if transition.event == VETTING_IN_PROCESS_EVENT
        user_for_vetting = transition.acting_user
      end
    end
    user_for_vetting
  end

  private

  def set_subject
    self.subject = subject_full_name
  end

  def use_subject_as_requester
    self.name = self.subject_full_name
  end

  def ensure_third_party_states_consistent
    # It should never have both `third_party requester`
    # AND `third_party recipient` but you can potentially get a case into
    # this state if you go back and edit the requester step
    # to change third_party to true
    # If this happens, we nudge recipient to the right option, requester_recipient
    if self.third_party && self.recipient == 'third_party_recipient'
      self.recipient = 'requester_recipient'
    end
  end
end
#rubocop:enable Metrics/ClassLength
