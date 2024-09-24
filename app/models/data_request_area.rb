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
  has_many :data_requests, dependent: :destroy
  has_one :commissioning_document
  has_many :data_request_emails

  validate :validate_location

  validates :data_request_area_type, presence: true
  validates :offender_sar_case, presence: true
  validates :user, presence: true

  attribute :data_request_default_area, default: ""

  before_validation :clean_attributes

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

  def completed?
    status == :completed
  end

  def status
    return :not_started unless data_requests.exists?

    data_requests.map(&:status).all?(:completed) ? :completed : :in_progress
  end

  def recipient_emails
    contact&.data_request_emails&.split(" ") || []
  end

  def build_commissioning_document
    template_class = case data_request_area_type
                     when "mappa"
                       CommissioningDocumentTemplate::Mappa
                     else
                       CommissioningDocumentTemplate::Standard
                     end

    commissioning_document = CommissioningDocument.find_or_initialize_by(data_request_area: self)
    commissioning_document.template_name = template_class.name.demodulize.underscore
    commissioning_document
  end

private

  def validate_location
    if contact_id.present?
      nil
    elsif location.blank?
      errors.add(
        :location,
        :blank,
      )
    end
  end

  def clean_attributes
    self.location = location&.strip&.upcase_first
  end
end
