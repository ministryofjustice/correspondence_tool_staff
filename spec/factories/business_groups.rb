FactoryBot.define do
  factory :business_group do
    transient do
      lead { create :director_general }
    end

    sequence(:name) { |n| "Business Group #{n}" }
    email { name.downcase.gsub(/\W/, '_') + '@localhost' }

    after(:create) do |bg, evaluator|
      bg.properties << evaluator.lead
    end
  end

  factory :operations_business_group, parent: :business_group do
    name 'Operations'
    email 'operations@localhost'
  end

end
