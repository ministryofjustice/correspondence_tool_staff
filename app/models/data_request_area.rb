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

  def kase
    offender_sar_case
  end

  def status
    completed? ? "Completed" : "In progress"
  end
end
