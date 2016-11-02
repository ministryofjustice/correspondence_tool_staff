FactoryGirl.define do

  factory :correspondence do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    email_confirmation { email }
    association :category, factory: :category, strategy: :create
    message { Faker::Lorem.paragraph(1) }
    received_date Time.zone.today.to_s
    postal_address { Faker::Address.street_address }
  end

end
