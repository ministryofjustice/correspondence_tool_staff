# == Schema Information
#
# Table name: cases
#
#  id             :integer          not null, primary key
#  name           :string
#  email          :string
#  message        :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  state          :string           default("submitted")
#  category_id    :integer
#  received_date  :date
#  postal_address :string
#  subject        :string
#  properties     :jsonb
#  reference      :string           not null
#

FactoryGirl.define do

  factory :case do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    association :category, factory: :category, strategy: :create
    subject { Faker::Hipster.sentence(1, word_count: 4) }
    message { Faker::Lorem.paragraph(1) }
    received_date Time.zone.today.to_s
    postal_address { Faker::Address.street_address }
  end

end
