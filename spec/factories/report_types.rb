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
#  etl                      :boolean          default(FALSE)
#  offender_sar             :boolean          default(FALSE)
#  offender_sar_complaint   :boolean          default(FALSE)
#

FactoryBot.define do
  factory :report_type do
    sequence(:abbr) { |n| "R#{n}" }
    sequence(:full_name) { |n| "Report #{n}" }
    class_name { full_name.classify.to_s }
    custom_report { false }
    sequence(:seq_id) { |n| n + 100 }
    default_reporting_period { "year_to_date" }
    etl { false }

    trait :r002 do
      abbr              { "R002" }
      full_name         { "Appeals report (FOI)" }
      class_name        { "Stats::R002AppealsPerformanceReport" }
      custom_report     { true }
      standard_report   { false }
      seq_id            { 100 }
      foi               { true }
      sar               { false }
    end

    trait :r003 do
      abbr              { "R003" }
      full_name         { "Business unit report" }
      class_name        { "Stats::R003BusinessUnitPerformanceReport" }
      custom_report     { true }
      standard_report   { true }
      seq_id            { 200 }
      foi               { true }
      sar               { false }
    end

    trait :r004 do
      abbr            { "R004" }
      full_name       { "Cabinet Office report" }
      class_name      { "Stats::R004CabinetOfficeReport" }
      custom_report   { true }
      standard_report { true }
      seq_id          { 400 }
      foi             { true }
      sar             { false }
    end

    trait :r005 do
      abbr              { "R005" }
      full_name         { "Monthly report" }
      class_name        { "Stats::R005MonthlyPerformanceReport" }
      custom_report     { true }
      standard_report   { true }
      seq_id            { 400 }
      foi               { true }
      sar               { false }
    end

    trait :r006 do
      abbr              { "R006" }
      full_name         { "Business unit map" }
      class_name        { "Stats::R006KiloMap" }
      custom_report     { false }
      standard_report   { false }
      seq_id            { 9999 }
      foi               { false }
      sar               { false }
    end

    trait :r007 do
      abbr              { "R007" }
      full_name         { "Closed in last month report" }
      class_name        { "Stats::R007ClosedCasesReport" }
      custom_report     { false }
      standard_report   { false }
      seq_id            { 500 }
      foi               { true }
      sar               { true }
      offender_sar      { false }
      etl               { true }
    end

    trait :r102 do
      abbr              { "R102" }
      full_name         { "Appeals performance report(SARs)" }
      class_name        { "Stats::R102SARAppealsPerformanceReport" }
      custom_report     { true }
      standard_report   { false }
      seq_id            { 320 }
      foi               { false }
      sar               { true }
    end

    trait :r103 do
      abbr              { "R103" }
      full_name         { "Business unit report" }
      class_name        { "Stats::R103SARBusinessUnitPerformanceReport" }
      custom_report     { true }
      standard_report   { false }
      seq_id            { 250 }
      foi               { false }
      sar               { true }
    end

    trait :r105 do
      abbr              { "R105" }
      full_name         { "Monthly report (SARs)" }
      class_name        { "Stats::R105SARMonthlyPerformanceReport" }
      custom_report     { true }
      standard_report   { true }
      seq_id            { 300 }
      foi               { false }
      sar               { true }
    end

    trait :r205 do
      abbr              { "R205" }
      full_name         { "Monthly report (Offender SARs)" }
      class_name        { "Stats::R205OffenderSARMonthlyPerformanceReport" }
      custom_report     { true }
      standard_report   { true }
      seq_id            { 600 }
      foi               { false }
      sar               { false }
      offender_sar      { true }
    end

    trait :r900 do
      abbr              { "R900" }
      full_name         { "Cases report" }
      class_name        { "Stats::R900CasesReport" }
      custom_report     { false }
      standard_report   { false }
      seq_id            { 900 }
      foi               { true }
      sar               { true }
      offender_sar      { false }
    end

    trait :r901 do
      abbr              { "R901" }
      full_name         { "Offender SAR cases report" }
      class_name        { "Stats::R901OffenderSARCasesReport" }
      custom_report     { false }
      standard_report   { false }
      seq_id            { 1000 }
      foi               { false }
      sar               { false }
      offender_sar      { true }
    end
  end
end
