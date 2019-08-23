class DataRequest < ApplicationRecord
  belongs_to :offender_sar_case, class_name: 'Case::SAR::Offender', foreign_key: 'case_id'
  belongs_to :user

  validates :location, presence: true, length: { minimum: 5, maximum: 500 }
  validates :data, presence: true, length: { minimum: 5 }
  validates :offender_sar_case, presence: true
  validates :user, presence: true
  validates :num_pages, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :clean_attributes

  def clean_attributes
    self.location = self.location&.strip
    self.data = self.data&.strip
  end
end
