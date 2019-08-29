FactoryBot.define do
  factory :data_request_log do
    association :data_request
    association :user
  end

  trait :received do
    date_received { Date.current }
    num_pages     { 11 }
  end
end
