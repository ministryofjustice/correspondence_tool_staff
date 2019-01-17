# == Schema Information
#
# Table name: report_types
#
#  id                       :integer          not null, primary key
#  abbr                     :string           not null
#  full_name                :string           not null
#  class_name               :string           not null
#  custom_report            :boolean          default(FALSE)
#  seq_id                   :integer          not null
#  foi                      :boolean          default(FALSE)
#  sar                      :boolean          default(FALSE)
#  standard_report          :boolean          default(FALSE), not null
#  default_reporting_period :string           default("year_to_date")
#

FactoryBot.define do
  factory :report_type do
    sequence(:abbr) { |n| "R#{n}" }
    sequence(:full_name) { |n| "Report #{n}" }
    class_name { "#{full_name.classify}" }
    custom_report { false }
    sequence(:seq_id) { |n| n + 100}
    default_reporting_period { 'year_to_date' }

    trait :r002 do
      abbr              { 'R002' }
      full_name         { 'Appeals report (FOI)' }
      class_name        { 'Stats::R002AppealsPerformanceReport' }
      custom_report     { true }
      standard_report   { false }
      seq_id            { 100 }
      foi               { true }
      sar               { false }
    end

    trait :r003 do
      abbr              { 'R003' }
      full_name         { 'Business unit report' }
      class_name        { 'Stats::R003BusinessUnitPerformanceReport' }
      custom_report     { true }
      standard_report   { true }
      seq_id            { 200 }
      foi               { true }
      sar               { false }
    end

    trait :r004 do
      abbr            { 'R004' }
      full_name       { 'Cabinet Office report' }
      class_name      { 'Stats::R004CabinetOfficeReport' }
      custom_report   { true }
      standard_report { true }
      seq_id          { 400 }
      foi             { true }
      sar             { false }
    end

    trait :r005 do
      abbr              { 'R005' }
      full_name         { 'Monthly report' }
      class_name        { 'Stats::R005MonthlyPerformanceReport' }
      custom_report     { true }
      standard_report   { true }
      seq_id            { 400 }
      foi               { true }
      sar               { false }
    end

    trait :r102 do
      abbr              { 'R102' }
      full_name         { 'Appeals performance report(SARs)' }
      class_name        { 'Stats::R102SarAppealsPerformanceReport' }
      custom_report     { true }
      standard_report   { true }
      seq_id            { 320 }
      foi               { false }
      sar               { true }
    end

    trait :r103 do
      abbr              { 'R103' }
      full_name         { 'Business unit report' }
      class_name        { 'Stats::R103SarBusinessUnitPerformanceReport' }
      custom_report     { true }
      standard_report   { true }
      seq_id            { 250 }
      foi               { false }
      sar               { true }
    end
  end

  factory :r105_report_type, parent: :report_type do
    abbr { 'R105' }
    full_name { 'Monthly report (SARs)' }
    class_name { 'Stats::R105SarMonthlyPerformanceReport' }
    custom_report { true }
    standard_report { true }
    foi { false }
    sar { true }
    seq_id { 300 }
  end

  factory :r006_business_unit_map, parent: :report_type do
    abbr { 'R006' }
    full_name { 'Business unit map' }
    class_name { 'Stats::R006KiloMap' }
    custom_report { false }
    standard_report { false }
    seq_id { 9999 }
  end


end
