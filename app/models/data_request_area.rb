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

  validates :data_request_area_type, presence: true
  validates :offender_sar_case, presence: true
  validates :user, presence: true

  #TODO this should call when attempting to send commissioning doc
  # validate  :validate_location

  attribute :data_request_default_area, default: ""
  attribute :data_request_area_type
  attribute :location

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
      "Completed"
    elsif data_requests.exists? && !data_requests.all?(&:completed)
      "In progress"
    else
      "Not started"
    end
  end

  private

  # def validate_location
  #   if contact_id.present?
  #     nil
  #   elsif location.blank?
  #     errors.add(
  #       :location,
  #       I18n.t("activerecord.errors.models.data_request_area.attributes.location.blank"),
  #       )
  #   end
  # end
end
