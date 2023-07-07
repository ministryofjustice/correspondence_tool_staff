FactoryBot.define do
  factory :data_request_email do
    association :data_request
    email_address { "test@user.com" }
  end
end
