# == Schema Information
#
# Table name: correspondence_types
#
#  id           :integer          not null, primary key
#  name         :string
#  abbreviation :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  properties   :jsonb
#

FactoryBot.define do
  factory :correspondence_type, aliases: [:foi_correspondence_type] do
    name { "Freedom of information request" }
    abbreviation { "FOI" }
    escalation_time_limit { 3 }
    internal_time_limit { 10 }
    external_time_limit { 20 }
    deadline_calculator_class { 'BusinessDays' }
    report_category_name { 'FOI report' }

    initialize_with { CorrespondenceType.find_or_create_by(name: name) }
  end

  factory :sar_correspondence_type, parent: :correspondence_type do
    name { 'Subject Access Request' }
    abbreviation { 'SAR' }
    escalation_time_limit { 3 }
    internal_time_limit { 10 }
    external_time_limit { 30 }
    deadline_calculator_class { 'CalendarDays' }
    report_category_name { 'SAR report' }


    initialize_with { CorrespondenceType.find_or_create_by(name: name) }
  end

  factory :gq_correspondence_type, parent: :correspondence_type do
    name { "General enquiry" }
    abbreviation { "GQ" }
    escalation_time_limit { 0 }
    external_time_limit { 15 }
    deadline_calculator_class { 'BusinessDays' }
    report_category_name { '' }

    initialize_with { CorrespondenceType.find_or_create_by(name: name) }
  end

  factory :ico_correspondence_type, parent: :correspondence_type do
    name { 'ICO' }
    abbreviation { 'ICO' }
    escalation_time_limit { 0 }
    external_time_limit { 15 }
    deadline_calculator_class { 'CalendarDays' }
    report_category_name { '' }
  end

  factory :overturned_sar_correspondence_type, parent: :sar_correspondence_type do
    name { 'Overturned ICO appeal (SAR)' }
    abbreviation { 'OVERTURNED_SAR' }
    report_category_name { '' }
  end

  factory :overturned_foi_correspondence_type, parent: :foi_correspondence_type do
    name { 'Overturned ICO appeal (FOI)' }
    abbreviation { 'OVERTURNED_FOI' }
    report_category_name { '' }
  end

  trait :business_days do
    deadline_calculator_class { 'BusinessDays' }
  end

  trait :calendar_days do
    deadline_calculator_class { 'CalendarDays' }
  end
end
