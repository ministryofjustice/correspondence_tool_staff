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

  before_validation :set_date_requested
  before_validation :clean_attributes

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

  private

  def update_cached_attributes(new_data_request_log)
    self.cached_date_received = new_data_request_log.date_received
    self.cached_num_pages = new_data_request_log.num_pages
  end

  def clean_attributes
    [:location, :request_type]
      .each { |f| self.send("#{f}=", self.send("#{f}")&.strip) }
      .each { |f| self.send("#{f}=", self.send("#{f}")&.upcase_first) }
  end

  def set_date_requested
    self.date_requested = Date.current if self.date_requested.blank?
  end
end
