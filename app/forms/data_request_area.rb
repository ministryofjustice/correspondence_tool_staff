class DataRequestArea
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attribute :data_request_area

  validates :data_request_area, presence: true

  DATA_REQUEST_AREAS = {
    "prison" => "Prison",
    "probation" => "Probation",
    "branston" => "Branston",
    "branston_registry" => "Branston Registry",
    "mappa" => "MAPPA"
  }.freeze
end
