class DataRequest < ApplicationRecord
  belongs_to :offender_sar_case, class_name: 'Case::SAR::Offender', foreign_key: 'case_id'
  belongs_to :user

  validates :location, presence: true, length: { minimum: 5, maximum: 500 }
  validates :data, presence: true, length: { minimum: 5 }
  validates :offender_sar_case, presence: true
  validates :user, presence: true

  before_validation :clean_attributes

  def clean_attributes
    self.location = self.location&.strip
    self.data = self.data&.strip
  end
end
