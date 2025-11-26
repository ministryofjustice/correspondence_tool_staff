# == Schema Information
#
# Table name: data_requests
#
#  id                      :integer          not null, primary key
#  case_id                 :integer          not null
#  user_id                 :integer          not null
#  location                :string
#  request_type            :enum             not null
#  date_requested          :date             not null
#  cached_date_received    :date
#  cached_num_pages        :integer          default(0), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  request_type_note       :text             default(""), not null
#  date_from               :date
#  date_to                 :date
#  completed               :boolean          default(FALSE), not null
#  contact_id              :bigint
#  email_branston_archives :boolean          default(FALSE)
#  data_request_area_id    :bigint
#
class DataRequest < ApplicationRecord
  belongs_to :offender_sar_case, class_name: "Case::Base", foreign_key: "case_id"
  belongs_to :user
  belongs_to :contact
  belongs_to :data_request_area
  has_one    :commissioning_document
  has_many   :data_request_emails

  validates :request_type, presence: true
  validates :offender_sar_case, presence: true
  validates :user, presence: true
  validates :date_requested, presence: true
  validates :cached_num_pages, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :validate_request_type_note
  validate :validate_from_date_before_to_date
  validate :validate_cached_date_received

  before_validation :clean_attributes

  # TODO: Replace "security" with a constant or enum value from somehere
  after_save do
    if data_request_area.data_requests.any? { |d| d.request_type == "security_records" } || request_type == "security_records"
      data_request_area.commissioning_document.update!(template_name: "security")
    else
      data_request_area.commissioning_document.update!(template_name: "standard")
    end
  end

  scope :completed, -> { where(completed: true) }
  scope :in_progress, -> { where(completed: false) }

  enum :request_type, {
    all_prison_records: "all_prison_records",
    security_records: "security_records",
    nomis_records: "nomis_records",
    nomis_other: "nomis_other",
    nomis_contact_logs: "nomis_contact_logs",
    probation_records: "probation_records",
    cctv_and_bwcf: "cctv_and_bwcf",
    telephone_recordings: "telephone_recordings",
    probation_archive: "probation_archive",
    mappa: "mappa",
    pdp: "pdp",
    court: "court",
    cross_borders: "cross_borders",
    cat_a: "cat_a",
    ndelius: "ndelius",
    dps: "dps",
    cctv: "cctv",
    bwcf: "bwcf",
    education: "education",
    oasys_arns: "oasys_arns",
    hpa: "hpa",
    g1_security: "g1_security",
    g2_security: "g2_security",
    g3_security: "g3_security",
    other_department: "other_department",
    other: "other",
    body_scans: "body_scans",
  }

  BRANSTON_DATA_REQUEST_TYPES          = %w[dps hpa nomis_contact_logs nomis_records nomis_other].freeze
  BRANSTON_REGISTRY_DATA_REQUEST_TYPES = %w[cat_a cross_borders pdp probation_archive].freeze
  MAPPA_DATA_REQUEST_TYPES             = %w[mappa].freeze
  PRISON_DATA_REQUEST_TYPES            = %w[all_prison_records body_scans bwcf cctv education security_records telephone_recordings other].freeze
  PROBATION_DATA_REQUEST_TYPES         = %w[ndelius oasys_arns probation_records other].freeze
  DPS_SENSITIVE_DATA_REQUEST_TYPES     = %w[g1_security g2_security g3_security].freeze
  OTHER_DEPARTMENT_DATA_REQUEST_TYPES  = %w[other_department].freeze

  acts_as_gov_uk_date(:date_requested, :cached_date_received, :date_from, :date_to)

  def kase
    offender_sar_case
  end

  def status
    completed? ? :completed : :in_progress
  end

  def other?
    request_type == "other"
  end

  def request_dates_either_present?
    date_from.present? || date_to.present?
  end

  def request_dates_both_present?
    date_from.present? && date_to.present?
  end

  def request_date_from_only?
    date_from.present? && date_to.blank?
  end

  def request_date_to_only?
    date_from.blank? && date_to.present?
  end

  def request_dates_absent?
    date_from.blank? && date_to.blank?
  end

  def data_request_types
    case data_request_area.data_request_area_type
    when "branston"
      BRANSTON_DATA_REQUEST_TYPES
    when "branston_registry"
      BRANSTON_REGISTRY_DATA_REQUEST_TYPES
    when "mappa"
      MAPPA_DATA_REQUEST_TYPES
    when "prison"
      PRISON_DATA_REQUEST_TYPES
    when "probation"
      PROBATION_DATA_REQUEST_TYPES
    when "dps_sensitive"
      DPS_SENSITIVE_DATA_REQUEST_TYPES
    when "other_department"
      OTHER_DEPARTMENT_DATA_REQUEST_TYPES
    end
  end

private

  def validate_from_date_before_to_date
    if request_dates_both_present? && date_from > date_to
      errors.add(
        :date_from,
        I18n.t("activerecord.errors.models.data_request.attributes.date_from.order"),
      )
      errors[:date_from].any?
    end
  end

  def validate_request_type_note
    if request_type == "other" && request_type_note.blank?
      errors.add(
        :request_type_note,
        I18n.t("activerecord.errors.models.data_request.attributes.request_type_note.blank"),
      )
      errors[:request_type_note].any?
    end
  end

  def validate_cached_date_received
    if completed?
      if cached_date_received.nil?
        errors.add(
          :cached_date_received,
          I18n.t("activerecord.errors.models.data_request.attributes.cached_date_received.blank"),
        )
      elsif cached_date_received > Time.zone.today
        errors.add(
          :cached_date_received,
          I18n.t("activerecord.errors.models.data_request.attributes.cached_date_received.future"),
        )
      end
    end
    if !completed? && cached_date_received.present?
      errors.add(
        :cached_date_received,
        I18n.t("activerecord.errors.models.data_request.attributes.cached_date_received.not_empty"),
      )
    end
  end

  def clean_attributes
    self.request_type_note = request_type_note&.strip&.upcase_first
  end
end
