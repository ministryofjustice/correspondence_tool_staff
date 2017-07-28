# == Schema Information
#
# Table name: teams
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  email      :citext           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  type       :string
#  parent_id  :integer
#

FactoryGirl.define do
  factory :team do
    sequence(:name) { |n| "Team #{n}" }
    email { Faker::Internet.email(name) }
  end
end
