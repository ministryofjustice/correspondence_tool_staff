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
  factory :team do
    transient do
      lead { create :team_lead }
    end

    sequence(:name) { |n| "Team #{n}" }
    email { "#{name.downcase.gsub(/\W/, '_')}@localhost" }

    after :create do |team, evaluator|
      team.properties << evaluator.lead
    end
  end
end
