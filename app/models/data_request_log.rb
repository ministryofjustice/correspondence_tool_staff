class DataRequestLog < ApplicationRecord
  belongs_to :data_request
  belongs_to :user

  validates :num_pages, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :date_received, presence: true
  validates :user, presence: true
  validates :data_request, presence: true
  validate :validate_date_received?

  acts_as_gov_uk_date :date_received

  def validate_date_received?
    return false if date_received.blank?

    if date_received > Time.zone.today
      errors.add(
        :date_received,
        I18n.t("activerecord.errors.models.data_request.attributes.date_received.future"),
      )
    end
    errors[:date_received].any?
  end
end
