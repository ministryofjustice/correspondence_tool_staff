# == Schema Information
#
# Table name: cases
#
#  id                       :integer          not null, primary key
#  name                     :string
#  email                    :string
#  message                  :text
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  received_date            :date
#  postal_address           :string
#  subject                  :string
#  properties               :jsonb
#  requester_type           :enum
#  number                   :string           not null
#  date_responded           :date
#  outcome_id               :integer
#  refusal_reason_id        :integer
#  current_state            :string
#  last_transitioned_at     :datetime
#  delivery_method          :enum
#  workflow                 :string
#  deleted                  :boolean          default(FALSE)
#  info_held_status_id      :integer
#  type                     :string
#  appeal_outcome_id        :integer
#  dirty                    :boolean          default(FALSE)
#  reason_for_deletion      :string
#  user_id                  :integer          default(-100), not null
#  reason_for_lateness_id   :bigint
#  reason_for_lateness_note :string
#
class Case::SAR::Offender < Case::Base
  belongs_to :reason_for_lateness, class_name: "CategoryReference"

  class << self
    def type_abbreviation
      "OFFENDER_SAR"
    end

    def searchable_fields_and_ranks
      {
        subject_full_name: "A",
        case_reference_number: "B",
        date_of_birth: "B",
        name: "B",
        number: "B",
        other_subject_ids: "B",
        postal_address: "B",
        previous_case_numbers: "B",
        prison_number: "B",
        requester_reference: "B",
        subject: "B",
        subject_address: "B",
        subject_aliases: "B",
        third_party_company_name: "B",
        third_party_name: "B",
      }
    end

    def close_expired_rejected
      Case::SAR::Offender.where(current_state: "invalid_submission").late.each do |kase|
        CaseClosureService.new(kase, User.system_admin, {}).call
      end
    end
  end

  include Stoppable

  DATA_SUBJECT_FOR_REQUESTEE_TYPE = "data_subject".freeze

  VETTING_IN_PROCESS_EVENT = "mark_as_vetting_in_progress".freeze
  VALIDATE_REJECTED_CASE_EVENT = "validate_rejected_case".freeze
  READY_FOR_COPY_EVENT = "mark_as_ready_to_copy".freeze

  GOV_UK_DATE_FIELDS = %i[
    date_of_birth
    date_responded
    external_deadline
    request_dated
    partial_case_letter_sent_dated
    received_date
    sent_to_sscl_at
  ].freeze

  REJECTED_AUTO_CLOSURE_DEADLINE = 90
  DPS_AUTO_CLOSURE_DEADLINE = 60

  REJECTED_REASONS = {
    "cctv_bwcf" => "CCTV / BWCF request",
    "change_of_name_certificate" => "Change of name certificate",
    "court_data_request" => "Court data request",
    "data_previously_requested" => "Data previously provided",
    "further_identification" => "Further identification",
    "identification_for_ex_inmate_probation" => "Identification for ex-inmate / probation",
    "illegible_handwriting_unreadable_content" => "Illegible handwriting / unreadable content",
    "id_required" => "ID required",
    "invalid_authority" => "Invalid authority",
    "medical_data" => "Medical data",
    "observation_book_entries" => "Observation book entries",
    "police_data" => "Police data ",
    "social_services_data" => "Social services data",
    "telephone_recordings_logs" => "Telephone recordings / logs",
    "telephone_transcripts" => "Telephone transcripts",
    "third_party_identification" => "Third party identification",
    "what_data_no_data_requested" => "What data / no data requested",
    "other" => "Other",
  }.freeze

  acts_as_gov_uk_date(*GOV_UK_DATE_FIELDS)

  jsonb_accessor :properties,
                 case_reference_number: :string,
                 date_of_birth: :date,
                 escalation_deadline: :date,
                 external_deadline: :date,
                 flag_as_high_profile: :boolean,
                 flag_as_dps_missing_data: :boolean,
                 internal_deadline: :date,
                 other_subject_ids: :string,
                 previous_case_numbers: :string,
                 prison_number: :string,
                 recipient: :string,
                 subject_address: :string,
                 request_dated: :date,
                 request_method: :string,
                 requester_reference: :string,
                 sent_to_sscl_at: :date,
                 subject_aliases: :string,
                 subject_full_name: :string,
                 subject_type: :string,
                 third_party_relationship: :string,
                 third_party: :boolean,
                 third_party_company_name: :string,
                 third_party_email: :string,
                 late_team_id: :integer,
                 third_party_name: :string,
                 number_final_pages: :integer,
                 number_exempt_pages: :integer,
                 is_partial_case: :boolean,
                 partial_case_letter_sent_dated: :date,
                 further_actions_required: :string,
                 case_originally_rejected: :boolean,
                 other_rejected_reason: :string,
                 rejected_reasons: [:string, { array: true, default: [] }],
                 probation_area: :string

  attribute :number_final_pages, :integer, default: 0
  attribute :number_exempt_pages, :integer, default: 0

  attr_accessor :remove_sent_to_sscl_reason

  enum :subject_type, {
    offender: "offender",
    ex_offender: "ex_offender",
    detainee: "detainee",
    ex_detainee: "ex_detainee",
    probation_service_user: "probation_service_user",
    ex_probation_service_user: "ex_probation_service_user",
  }

  enum :recipient, {
    subject_recipient: "subject_recipient",
    requester_recipient: "requester_recipient",
    third_party_recipient: "third_party_recipient",
  }

  enum :further_actions_required, {
    yes: "yes",
    no: "no",
    awaiting_response: "awaiting_response",
  }

  enum :request_method, {
    email: "email",
    ico_web_portal: "ico web portal",
    post: "post",
    verbal_request: "verbal request",
    web_portal: "web portal",
    unknown: "unknown",
  }

  has_paper_trail only: %i[
    name
    email
    postal_address
    properties
    received_date
  ]

  has_many :data_requests, dependent: :destroy, foreign_key: :case_id
  has_many :data_request_areas, dependent: :destroy, foreign_key: :case_id

  accepts_nested_attributes_for :data_requests

  validates :third_party,              inclusion: { in: [true, false], message: "cannot be blank" }
  validates :flag_as_high_profile,     inclusion: { in: [true, false], message: "cannot be blank" }
  validates :flag_as_dps_missing_data, inclusion: { in: [true, false], message: "cannot be blank" }, if: -> { rejected? }

  validates :subject_address, presence: true
  validates :subject_full_name, presence: true
  validates :subject_type, presence: true
  validates :recipient, presence: true

  validate :validate_date_of_birth
  validate :validate_received_date
  validate :validate_third_party_names
  validate :validate_recipient
  validate :validate_third_party_relationship
  validate :validate_third_party_address
  validate :validate_third_party_email_format
  validate :validate_request_dated
  validates :request_method, presence: true, unless: :offender_sar_complaint?

  validates :number_final_pages,
            numericality: { only_integer: true,
                            greater_than: -1,
                            message: "must be a positive whole number" }
  validates :number_exempt_pages,
            numericality: { only_integer: true,
                            greater_than: -1,
                            message: "must be a positive whole number" }
  validate :validate_third_party_states_consistent
  validate :validate_partial_flags
  validate :validate_partial_case_letter_sent_dated
  validate :validate_sent_to_sscl_at
  validate :validate_remove_sent_to_sscl_reason
  validate :validate_rejected_reason, if: -> { invalid_submission? }

  before_validation :ensure_third_party_states_consistent
  before_validation :reassign_gov_uk_dates
  before_save :set_subject
  before_save :use_subject_as_requester,
              if: -> { name.blank? }
  before_save :set_case_originally_rejected, if: -> { invalid_submission? }
  before_save :verify_other_rejected_reason, if: -> { invalid_submission? }

  def validate_third_party_states_consistent
    if third_party && recipient == "third_party_recipient"
      errors.add(
        :recipient,
        I18n.t("activerecord.errors.models.case/sar/offender.attributes.recipient.third_party"),
      )
    end
    errors[:recipient].any?
  end

  def validate_received_date # rubocop:disable Lint/UselessMethodDefinition
    super
  end

  def validate_date_of_birth
    if date_of_birth.nil?
      errors.add(:date_of_birth, :blank)
    end

    if date_of_birth.present? && date_of_birth > Time.zone.today
      errors.add(
        :date_of_birth,
        I18n.t("activerecord.errors.models.case.attributes.date_of_birth.not_in_future"),
      )
    end
    errors[:date_of_birth].any?
  end

  def validate_request_dated
    if request_dated.present? && request_dated > Time.zone.today
      errors.add(
        :request_dated,
        I18n.t("activerecord.errors.models.case.attributes.request_dated.not_in_future"),
      )
    end
  end

  def validate_third_party_names
    if third_party && third_party_company_name.blank? && third_party_name.blank?
      errors.add(
        :third_party_name,
        I18n.t("activerecord.errors.models.case/sar/offender.attributes.third_party_name.blank"),
      )
      errors.add(
        :third_party_company_name,
        I18n.t("activerecord.errors.models.case/sar/offender.attributes.third_party_company_name.blank"),
      )
    end
  end

  def validate_recipient
    if recipient == "third_party_recipient" && third_party_company_name.blank? && third_party_name.blank?
      errors.add(
        :third_party_name,
        I18n.t("activerecord.errors.models.case/sar/offender.attributes.third_party_name.blank"),
      )
      errors.add(
        :third_party_company_name,
        I18n.t("activerecord.errors.models.case/sar/offender.attributes.third_party_company_name.blank"),
      )
    end
  end

  def validate_third_party_relationship
    if (third_party || recipient == "third_party_recipient") && third_party_relationship.blank?
      errors.add(
        :third_party_relationship,
        I18n.t("activerecord.errors.models.case/sar/offender.attributes.third_party_relationship.blank"),
      )
    end
  end

  def validate_third_party_address
    if (third_party || recipient == "third_party_recipient") && postal_address.blank?
      errors.add(
        :postal_address,
        I18n.t("activerecord.errors.models.case/sar/offender.attributes.third_party_address.blank"),
      )
    end
  end

  def validate_third_party_email_format
    if third_party && (third_party_email.present? && third_party_email !~ /\A.+@.+\z/)
      errors.add(
        :third_party_email,
        :invalid,
      )
    end
  end

  def validate_partial_flags
    if !is_partial_case && further_actions_required == "yes"
      errors.add(
        :is_partial_case,
        I18n.t("activerecord.errors.models.case/sar/offender.attributes.is_partial_case.invalid"),
      )
    end
  end

  def validate_partial_case_letter_sent_dated
    if is_partial_case? && partial_case_letter_sent_dated.present? && partial_case_letter_sent_dated > Time.zone.today
      errors.add(
        :partial_case_letter_sent_dated,
        I18n.t("activerecord.errors.models.case.attributes.partial_case_letter_sent_dated.not_in_future"),
      )
    end
  end

  def validate_sent_to_sscl_at
    if remove_sent_to_sscl_reason.present? && sent_to_sscl_at.present?
      errors.add(
        :sent_to_sscl_at,
        I18n.t("activerecord.errors.models.case.attributes.sent_to_sscl_at.not_allowed"),
      )
    end
  end

  def validate_remove_sent_to_sscl_reason
    if sent_to_sscl_at.blank? && sent_to_sscl_at_was.present? && remove_sent_to_sscl_reason.blank?
      errors.add(
        :remove_sent_to_sscl_reason,
        I18n.t("activerecord.errors.models.case.attributes.remove_sent_to_sscl_reason.blank"),
      )
    end
  end

  def validate_rejected_reason
    if rejected_reasons.all?(&:blank?)
      errors.add(
        :rejected_reasons,
        I18n.t("activerecord.errors.models.case/sar/offender.attributes.rejected_reasons.blank"),
      )
    end

    if rejected_reasons.include?("other") && other_rejected_reason.empty?
      errors.add(
        :other_rejected_reason,
        I18n.t("activerecord.errors.models.case/sar/offender.attributes.other_rejected_reason.blank"),
      )
    end
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
    reassign = GOV_UK_DATE_FIELDS.map(&:to_s) - changed
    reassign.each do |field|
      send("#{field}=", self[field])
    end
  end

  # User can add data requests at any point in the workflow, but
  # the case state should not change
  def allow_waiting_for_data_state?
    current_state == "data_to_be_requested"
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

    third_party_name.presence || ""
  end

  def recipient_address
    !subject_recipient? ? postal_address : subject_address
  end

  def page_count
    DataRequest.where(case_id: id).sum(:cached_num_pages)
  end

  def requester_type
    third_party? ? third_party_relationship : "data_subject"
  end

  def data_requests_completed?
    data_requests = DataRequest.where(case_id: id)
    if data_requests.empty?
      false
    else
      data_requests.all?(&:completed)
    end
  end

  def first_prison_number
    return "" if prison_number.blank?

    prison_number.gsub(/,/, " ").split(" ").first.upcase
  end

  def number_of_days_for_vetting
    # Get the start date and end date for the vetting process
    start_date_for_vetting = nil
    end_date_for_vetting = nil
    transitions.each do |transition|
      if transition.event == VETTING_IN_PROCESS_EVENT
        start_date_for_vetting = transition.created_at.to_date
      end
      if transition.event == READY_FOR_COPY_EVENT
        end_date_for_vetting = transition.created_at.to_date
      end
    end
    end_date_for_vetting ||= Time.zone.today
    # Calculate the days taken for vetting process
    days = nil
    if start_date_for_vetting
      days = start_date_for_vetting.business_days_until(end_date_for_vetting, true)
    end
    days
  end

  def user_dealing_with_vetting
    user_for_vetting = nil
    transitions.each do |transition|
      if transition.event == VETTING_IN_PROCESS_EVENT
        user_for_vetting = transition.acting_user
      end
    end
    user_for_vetting
  end

  def assign_vetter(user)
    responder_assignment&.update(user:)
  end

  def unassign_vetter
    responder_assignment&.update(user: nil)
  end

  def user_validated_rejected_case
    user_for_validation = nil
    transitions.each do |transition|
      if transition.event == VALIDATE_REJECTED_CASE_EVENT
        user_for_validation = transition.acting_user
      end
    end
    user_for_validation
  end

  def rejected?
    if number.present? && persisted?
      number[0] == "R"
    else
      current_state == "invalid_submission"
    end
  end

  # Overwrites base method to allow case number to remove "R" when
  # transitioning from 'invalid' to 'valid' offender SAR
  def prevent_number_change
    raise StandardError, "number is immutable" if current_state != "invalid_submission" && number_changed?
  end

  def set_valid_case_number
    self.number = if flag_as_dps_missing_data?
                    "D#{next_number}"
                  else
                    next_number
                  end
  end

private

  def set_subject
    self.subject = subject_full_name
  end

  def use_subject_as_requester
    self.name = subject_full_name
  end

  def set_case_originally_rejected
    self.case_originally_rejected = true
  end

  def verify_other_rejected_reason
    self.other_rejected_reason = "" unless rejected_reasons.include?("other")
  end

  def ensure_third_party_states_consistent
    # It should never have both `third_party requester`
    # AND `third_party recipient` but you can potentially get a case into
    # this state if you go back and edit the requester step
    # to change third_party to true
    # If this happens, we nudge recipient to the right option, requester_recipient
    if third_party && recipient == "third_party_recipient"
      self.recipient = "requester_recipient"
    end
  end

  def set_number
    self.number = if invalid_submission?
                    if flag_as_dps_missing_data?
                      "DR#{next_number}"
                    else
                      "R#{next_number}"
                    end
                  else
                    next_number
                  end
  end

  def set_deadlines
    super
    if rejected? & flag_as_dps_missing_data?
      self.external_deadline = @deadline_calculator.days_after(DPS_AUTO_CLOSURE_DEADLINE, received_date)
    elsif rejected?
      self.external_deadline = @deadline_calculator.days_after(REJECTED_AUTO_CLOSURE_DEADLINE, received_date)
    end
  end

  def update_deadlines
    super
    if changed.include?("received_date") && rejected?
      self.external_deadline = @deadline_calculator.days_after(REJECTED_AUTO_CLOSURE_DEADLINE, received_date)
    end
  end
end
