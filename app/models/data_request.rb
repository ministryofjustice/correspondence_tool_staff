class DataRequest < ApplicationRecord
  belongs_to :offender_sar_case, class_name: 'Case::SAR::Offender', foreign_key: 'case_id'
  belongs_to :user
  has_many   :data_request_logs, after_add: :update_cached_attributes

  validates :location, presence: true, length: { maximum: 500 }
  validates :request_type, presence: true
  validates :offender_sar_case, presence: true
  validates :user, presence: true
  validates :date_requested, presence: true
  validates :cached_num_pages, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :validate_request_type_note
  validate :validate_from_date_before_to_date

  before_validation :set_date_requested
  before_validation :clean_attributes

  scope :completed, -> { where(completed: true) }
  scope :in_progress, -> { where(completed: false) }

  enum request_type: {
    all_prison_records: 'all_prison_records',
    security_records: 'security_records',
    nomis_records: 'nomis_records',
    nomis_contact_logs: 'nomis_contact_logs',
    probation_records: 'probation_records',
    prison_and_probation_records: 'prison_and_probation_records',
    other: 'other'
  }

  acts_as_gov_uk_date(:date_from, :date_to)

  def new_log
    logs.new(
      date_received: self.cached_date_received,
      num_pages: self.cached_num_pages,
    )
  end

  def logs
    self.data_request_logs
  end

  def kase
    self.offender_sar_case
  end

  def status
    completed? ? 'Completed' : 'In progress'
  end

  private

  def validate_from_date_before_to_date
    if dates_present? && date_from > date_to
      errors.add(
        :date_from,
        I18n.t('activerecord.errors.models.data_request.attributes.date_from.order')
      )
      errors[:date_from].any?
    end
  end

  def dates_present?
    date_from.present? && date_to.present?
  end

  def validate_request_type_note
    if request_type == 'other' && request_type_note.blank?
      errors.add(
        :request_type_note,
        I18n.t('activerecord.errors.models.data_request.attributes.request_type_note.blank')
      )
      errors[:request_type_note].any?
    end
  end

  def update_cached_attributes(new_data_request_log)
    self.cached_date_received = new_data_request_log.date_received
    self.cached_num_pages = new_data_request_log.num_pages
  end

  def clean_attributes
    [:location, :request_type_note]
      .each { |f| self.send("#{f}=", self.send("#{f}")&.strip) }
      .each { |f| self.send("#{f}=", self.send("#{f}")&.upcase_first) }
  end

  def set_date_requested
    self.date_requested = Date.current if self.date_requested.blank?
  end
end
