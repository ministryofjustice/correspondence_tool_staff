# == Schema Information
#
# Table name: reports
#
#  id             :integer          not null, primary key
#  report_type_id :integer          not null
#  period_start   :date
#  period_end     :date
#  report_data    :binary
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  guid           :string
#  properties     :jsonb
#

FactoryBot.define do
  factory :report do
    report_type
    correspondence_type { "FOI" }
    period_start { 10.business_days.ago }
    period_end { 1.business_days.ago }
    report_data { Faker::Hipster.paragraph }
    guid { SecureRandom.uuid }
  end

  factory :r003_report, parent: :report do
    report_type { find_or_create(:report_type, :r003) }
  end

  factory :r004_report, parent: :report do
    report_type { find_or_create(:report_type, :r004) }
  end

  factory :r005_report, parent: :report do
    report_type { find_or_create(:report_type, :r005) }
  end

  factory :r007_report, parent: :report do
    report_type { find_or_create(:report_type, :r007) }
    report_data { { status: Stats::BaseReport::WAITING }.to_json }
  end
end
