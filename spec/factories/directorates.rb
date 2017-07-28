FactoryGirl.define do
  factory :directorate do
    sequence(:name) { |n| "Directorate #{n}" }
    email { Faker::Internet.email(name) }
    association :business_group
  end
end
