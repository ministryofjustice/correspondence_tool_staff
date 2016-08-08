FactoryGirl.define do
  factory :user do
    email { Faker::Internet.email }
    password '12345678'
    roles %w[assigner drafter]
  end
end
