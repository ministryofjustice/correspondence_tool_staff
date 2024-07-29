class DataRequestArea < ApplicationRecord
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
