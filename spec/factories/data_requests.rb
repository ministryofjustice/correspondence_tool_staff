FactoryBot.define do
  factory :data_request do
    association :offender_sar_case
    association :user

    location        { Faker::Company.name }
    request_type    { "all_prison_records" }
    date_requested  { Date.current }

    trait :other do
      request_type { "other" }
      request_type_note { "Lorem ipsum" }
    end

    trait :with_date_range do
      date_from { Date.new(2018, 0o1, 0o1) }
      date_to { Date.new(2018, 12, 31) }
    end

    trait :with_date_from do
      date_from { Date.new(2018, 0o1, 0o1) }
    end

    trait :with_date_to do
      date_to { Date.new(2018, 12, 31) }
    end

    trait :completed do
      completed { true }
    end
  end
end
