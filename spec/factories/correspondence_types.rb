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

FactoryGirl.define do
  factory :correspondence_type, aliases: [:foi_correspondence_type] do

    name "Freedom of information request"
    abbreviation "FOI"
    escalation_time_limit 3
    internal_time_limit 10
    external_time_limit 20
    deadline_calculator_class 'BusinessDays'

    initialize_with { CorrespondenceType.find_or_create_by(name: name) }
  end

  factory :sar_correspondence_type, parent: :correspondence_type do
    name 'Subject Access Request'
    abbreviation 'SAR'
    escalation_time_limit(-1)
    internal_time_limit 10
    external_time_limit 30
    deadline_calculator_class 'CalendarDays'


    initialize_with { CorrespondenceType.find_or_create_by(name: name) }
  end

  factory :gq_correspondence_type, parent: :correspondence_type do
    name "General enquiry"
    abbreviation "GQ"
    escalation_time_limit 0
    external_time_limit 15
    deadline_calculator_class 'BusinessDays'

    initialize_with { CorrespondenceType.find_or_create_by(name: name) }
  end

  trait :business_days do
    deadline_calculator_class 'BusinessDays'
  end

  trait :calendar_days do
    deadline_calculator_class 'CalendarDays'
  end
end
