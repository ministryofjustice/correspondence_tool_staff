# == Schema Information
#
# Table name: teams
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  email      :citext
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  type       :string
#  parent_id  :integer
#  role       :string
#  code       :string
#  deleted_at :datetime
#

FactoryBot.define do
  factory :business_group do
    transient do
      lead { create :director_general }
    end

    sequence(:name) { |n| "Business Group #{n}" }
    email { "#{name.downcase.gsub(/\W/, '_')}@localhost" }

    after(:create) do |bg, evaluator|
      bg.properties << evaluator.lead
    end
  end

  factory :operations_business_group, parent: :business_group do
    name  { "Operations" }
    email { "operations@localhost" }
  end

  factory :responder_business_group, parent: :business_group do
    name  { "Responder Business Group" }
    email { "responder-bg@localhost" }
  end
end
