FactoryGirl.define do
  factory :business_group do
    sequence(:name) { |n| "Business Group #{n}" }
    sequence(:email) { |n| "business_group_#{n}@localhost"}
  end

  factory :operations_business_group, parent: :business_group do
    name 'Operations'
    email 'operations@localhost'
  end
end
