FactoryGirl.define do
  factory :business_group do
    sequence(:name) { |n| "Business Group #{n}" }
    email { Faker::Internet.email(name) }
  end

  factory :operations_business_group, parent: :business_group do
    name 'Operations'
    email 'operations@localhost'
  end
end
