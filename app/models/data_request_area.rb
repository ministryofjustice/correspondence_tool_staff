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
  has_one :commissioning_document
  has_many :data_request_emails

  validates :data_request_area_type, presence: true
  validates :offender_sar_case, presence: true
  validates :user, presence: true

  attribute :data_request_default_area, default: ""

  before_validation :clean_attributes

  #TODO this should call when attempting to send commissioning doc
  # validate  :validate_location

  scope :completed, -> { joins(:data_requests).where(data_requests: { completed: true }).distinct }
  scope :in_progress, -> { joins(:data_requests).where(data_requests: { completed: false }).distinct }
  scope :not_started, -> { where.not(id: DataRequest.select(:data_request_area_id)) }

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
      :completed
    elsif data_requests.exists? && !data_requests.all?(&:completed)
      :in_progress
    else
      :not_started
    end
  end

  private

  def clean_attributes
    %i[location]
      .each { |f| send("#{f}=", send(f.to_s)&.strip) }
      .each { |f| send("#{f}=", send(f.to_s)&.upcase_first) }
  end
end
