FactoryGirl.define do
  factory :report do
    report_type
    period_start { 10.business_days.ago}
    period_end { 1.business_days.ago}
    report_data { Faker::Hipster.paragraph }
  end
end
