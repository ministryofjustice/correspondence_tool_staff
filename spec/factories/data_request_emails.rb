FactoryBot.define do
  factory :data_request_email do
    association :data_request
    email_address { "test@user.com" }
  end

  trait :sent_to_notify do
    notify_id { "35daaa7a-2859-4c39-a5f2-bfdb17a053f4" }
  end
end
