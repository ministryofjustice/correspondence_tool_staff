class DataRequest < ApplicationRecord
  belongs_to :offender_sar_case, class_name: 'Case::Base', foreign_key: 'case_id'
  belongs_to :user
  has_many   :data_request_logs, after_add: :update_cached_attributes, dependent: :destroy

  validates :location, presence: true, length: { maximum: 500 }
  validates :request_type, presence: true
  validates :date_requested, presence: true
  validates :cached_num_pages, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :validate_request_type_note
  validate :validate_from_date_before_to_date
  validate :validate_cached_date_received

  before_validation :clean_attributes

  scope :completed, -> { where(completed: true) }
  scope :in_progress, -> { where(completed: false) }

  enum request_type: {
    all_prison_records: 'all_prison_records',
    security_records: 'security_records',
    nomis_records: 'nomis_records',
    nomis_other: 'nomis_other',
    nomis_contact_logs: 'nomis_contact_logs',
    probation_records: 'probation_records',
    cctv_and_bwcf: 'cctv_and_bwcf',
    telephone_recordings: 'telephone_recordings',
    probation_archive: 'probation_archive',
    mappa: 'mappa',
    pdp: 'pdp',
    court: 'court',
    other: 'other'
  }

  acts_as_gov_uk_date(:date_requested, :cached_date_received, :date_from, :date_to)

  def logs
    self.data_request_logs
  end

  def kase
    self.offender_sar_case
  end

  def status
    completed? ? 'Completed' : 'In progress'
  end

  def other?
    request_type == 'other'
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

  private

  def validate_from_date_before_to_date
    if request_dates_both_present? && date_from > date_to
      errors.add(
        :date_from,
        I18n.t('activerecord.errors.models.data_request.attributes.date_from.order')
      )
      errors[:date_from].any?
    end
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

  def validate_cached_date_received
    if completed?
      if cached_date_received.nil?
        errors.add(
          :cached_date_received,
          I18n.t('activerecord.errors.models.data_request.attributes.cached_date_received.blank')
        )
      elsif cached_date_received > Time.current.to_date
        errors.add(
          :cached_date_received,
          I18n.t('activerecord.errors.models.data_request.attributes.cached_date_received.future')
        )
      end
    end
    if not completed? and cached_date_received.present?
      errors.add(
        :cached_date_received,
        I18n.t('activerecord.errors.models.data_request.attributes.cached_date_received.not_empty')
      )
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
end
