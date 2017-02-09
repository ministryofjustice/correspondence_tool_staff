FactoryGirl.define do
  factory :feedback do
    comment { Faker::Lorem.paragraph(1) }
    email {  Faker::Internet.email }
  end
end
