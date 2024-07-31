class DataRequestArea < ApplicationRecord
  belongs_to :offender_sar_case, class_name: "Case::Base", foreign_key: "case_id"
  belongs_to :user
  belongs_to :contact
  has_many :data_requests

  validates :data_request_area_type, presence: true
  attribute :data_request_default_area, default: ""

  attribute :data_request_area_type

  scope :completed, -> { where(completed: true) }
  scope :in_progress, -> { where(completed: false) }

  enum data_request_area_type: {
    prison: "prison",
    probation: "probation",
    branston: "branston",
    branston_registry: "branston_registry",
    mappa: "mappa"
  }

  acts_as_gov_uk_date(:date_requested, :cached_date_received, :date_from, :date_to)

  def kase
    offender_sar_case
  end

  def status
    completed? ? "Completed" : "In progress"
  end

  def num_of_requests
    data_requests.count
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
end
