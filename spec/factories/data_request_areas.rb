FactoryBot.define do
  factory :data_request_area do
    association :offender_sar_case
    association :user

    data_request_area_type    { "prison" }
    date_requested  { Date.current }
  end
end
