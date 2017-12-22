FactoryGirl.define do

  factory :sar_case,
          class: Case::SAR do
    transient do
      creation_time             { 4.business_days.ago }
      identifier                "new case"
      managing_team             { find_or_create :team_dacu }
    end

    current_state                 'unassigned'
    requester_type                'member_of_the_public'
    sequence(:name)               { |n| "#{identifier} name #{n}" }
    email                         { Faker::Internet.email(identifier) }
    category
    delivery_method               'sent_by_email'
    sequence(:subject)            { |n| "#{identifier} subject #{n}" }
    sequence(:message)            { |n| "#{identifier} message #{n}" }
    received_date                 { Time.zone.today.to_s }
    sequence(:postal_address)     { |n| "#{identifier} postal address #{n}" }
    sequence(:subject_full_name)  { |n| "Subject #{n}" }
    subject_type                  'Offender'
    third_party                   false
    created_at                    { creation_time }

    after(:build) do |_kase, evaluator|
      evaluator.managing_team
    end

    after(:create) do | kase, evaluator|
      ma = kase.managing_assignment
      ma.update! created_at: evaluator.creation_time
    end
  end
end

