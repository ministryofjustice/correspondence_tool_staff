FactoryGirl.define do
  factory :directorate do
    transient do
      lead { create :director }
    end

    sequence(:name) { |n| "Directorate #{n}" }
    email { name.downcase.gsub(/\W/, '_') + '@localhost' }
    business_group { find_or_create :business_group }

    after(:create) do |dir, evaluator|
      dir.properties << evaluator.lead
    end
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
