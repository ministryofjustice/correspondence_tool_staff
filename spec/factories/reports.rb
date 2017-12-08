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
#

FactoryGirl.define do
  factory :report do
    report_type
    period_start { 10.business_days.ago}
    period_end { 1.business_days.ago}
    report_data { Faker::Hipster.paragraph }
  end
end
