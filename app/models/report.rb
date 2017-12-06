class Report < ApplicationRecord
  acts_as_gov_uk_date :period_start, :period_end

  belongs_to :report_type, required: true

  validates :report_type_id,
            :period_start, :period_end,
            presence: true

  validates :report_data, presence: true, on: :create
end
