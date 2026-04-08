# == Schema Information
#
# Table name: reports_caches
#
#  id          :bigint           not null, primary key
#  report_type :string           not null
#  data        :jsonb            not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class ReportsCache < ApplicationRecord
  self.table_name = "reports_caches"

  validates :report_type, presence: true
  validates :data, presence: true

  scope :for_type, ->(report_type) { where(report_type:) }
  scope :latest_first, -> { order(created_at: :desc) }

  def self.latest_for(report_type)
    for_type(report_type).latest_first.first
  end

  # Upsert latest entry by report_type. Keeps history but ensures newest is retrievable quickly.
  def self.store!(report_type:, data:)
    create!(report_type:, data: data)
  end
end
