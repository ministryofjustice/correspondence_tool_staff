FactoryBot.define do
  factory :data_request do
    association :offender_sar_case
    association :user

    location        { Faker::Company.name }
    data            { Faker::Lorem.sentences(5).join }
    date_requested  { Date.current }
  end
end

