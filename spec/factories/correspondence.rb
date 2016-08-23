FactoryGirl.define do

  factory :correspondence do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    email_confirmation { email }
    association :category, factory: :category, strategy: :create
    topic 'prisons'
    message { Faker::Lorem.paragraph(1) }
  end

end
