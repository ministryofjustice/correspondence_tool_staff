class DataRequest < ApplicationRecord
  belongs_to :offender_sar_case, class_name: 'Case::SAR::Offender', foreign_key: 'case_id'
  belongs_to :user

  validates :location, presence: true, length: { minimum: 5, maximum: 500 }
  validates :data, presence: true, length: { minimum: 5 }
  validates :offender_sar_case, presence: true
  validates :user, presence: true
  validates :num_pages, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :date_requested, presence: true
  validates :date_received, presence: true, on: :update
  validate :validate_date_received?

  before_validation :clean_attributes

  acts_as_gov_uk_date :date_received

  def kase
    self.offender_sar_case
  end

  def previous_num_pages
    0
  end


  private

  def clean_attributes
    [:location, :data]
      .each { |f| self.send("#{f}=", self.send("#{f}")&.strip) }
      .each { |f| self.send("#{f}=", self.send("#{f}")&.upcase_first) }
  end

  def validate_date_received?
    return false if self.date_received.blank?

    if self.date_received > Date.today
      errors.add(
        :date_received,
        I18n.t('activerecord.errors.models.data_request.attributes.date_received.future')
      )
    end
    errors[:date_received].any?
  end
end
