class DataRequestEmail < ApplicationRecord
  belongs_to :data_request

  validates :data_request, presence: true
  validates :email_address, presence: true
  validates :status, presence: true

  enum email_type: { commissioning_email: 0 }

  attribute :status, default: "created"
end
