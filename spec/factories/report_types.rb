FactoryGirl.define do
  factory :report_type do
    sequence(:abbr) { |n| "R#{n}" }
    sequence(:full_name) { |n| "Report #{n}" }
    class_name { "#{full_name.classify}"}
    custom_report false
    sequence(:seq_id) { |n| "n"}
  end

  factory :r003_business_units do
    abbr "R003"
    full_name "Business unit report"
    class_name { "R003BusinessUnitPerformanceReport"}
    custom_report true
    seq_id 100
  end
end
