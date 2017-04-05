# == Schema Information
#
# Table name: teams
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  email      :citext           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryGirl.define do
  factory :team do
    sequence(:name) { |n| "Team #{n}" }
    email { Faker::Internet.email(name) }
  end

  factory :managing_team, parent: :team do
    sequence(:name) { |n| "Managing Team #{n}" }
    managers { [create(:user)] }
  end

  factory :responding_team, parent: :team do
    sequence(:name) { |n| "Responding Team #{n}" }
    responders { [create(:user)] }
  end

  factory :team_dacu, parent: :managing_team do
    name 'DACU'
    email 'dacu@localhost'

    initialize_with do
      Team.find_or_create_by(name: name, email: email)
    end
  end
end
