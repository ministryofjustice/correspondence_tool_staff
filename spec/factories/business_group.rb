FactoryGirl.define do
  factory :business_group do
    sequence(:name) { |n| "Business Group #{n}" }
    email { Faker::Internet.email(name) }
  end
end
