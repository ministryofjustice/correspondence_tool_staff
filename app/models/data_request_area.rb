class DataRequestArea < ApplicationRecord
  belongs_to :offender_sar_case, class_name: "Case::Base", foreign_key: "case_id"
  belongs_to :user
  has_many :data_requests

  attribute :data_request_area

  validates :data_request_area, presence: true
  attribute :data_request_default_area, default: ""

  attribute :data_request_area_type

  enum data_request_area_type: {
    prison: "Prison",
    probation: "Probation",
    branston: "Branston",
    branston_registry: "Branston Registry",
    mappa: "MAPPA"
  }
end
