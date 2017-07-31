FactoryGirl.define do
  factory :directorate do
    sequence(:name) { |n| "Directorate #{n}" }
    email { Faker::Internet.email(name) }
    association :business_group
  end

  factory :dacu_directorate, parent: :directorate do
    name 'DACU Directorate'
    email 'dacu@localhost'
    business_group { find_or_create :operations_business_group }
  end

  factory :press_office_directorate, parent: :directorate do
    name 'Press Office Directorate'
    email 'press_office@localhost'
    business_group { find_or_create :operations_business_group }
  end

  factory :private_office_directorate, parent: :directorate do
    name 'Private Office Directorate'
    email 'private_office@localhost'
    business_group { find_or_create :operations_business_group }
  end
end
