# == Schema Information
#
# Table name: data_request_areas
#
#  id                     :bigint           not null, primary key
#  case_id                :bigint           not null
#  user_id                :bigint           not null
#  contact_id             :bigint
#  data_request_area_type :enum             not null
#  location               :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
class DataRequestArea < ApplicationRecord
  belongs_to :offender_sar_case, class_name: "Case::Base", foreign_key: "case_id"
  belongs_to :user
  belongs_to :contact
  has_many :data_requests

  validates :data_request_area_type, presence: true
  attribute :data_request_default_area, default: ""

  attribute :data_request_area_type

  scope :completed, -> { data_requests.where(completed: true) }
  scope :in_progress, -> { data_requests.where(completed: false) }

  enum data_request_area_type: {
    prison: "prison",
    probation: "probation",
    branston: "branston",
    branston_registry: "branston_registry",
    mappa: "mappa",
  }

  def kase
    offender_sar_case
  end

  def status
    if data_requests.exists? && data_requests.all?(&:completed)
      "Completed"
    elsif data_requests.exists? && !data_requests.all?(&:completed)
      "In progress"
    else
      "Not started"
    end
  end
end
