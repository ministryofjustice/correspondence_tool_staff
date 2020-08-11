FactoryBot.define do
  factory :data_request do
    association :offender_sar_case
    association :user

    location        { Faker::Company.name }
    request_type    { Faker::Lorem.sentences(number: 5).join }
    date_requested  { Date.current }
  end
end

