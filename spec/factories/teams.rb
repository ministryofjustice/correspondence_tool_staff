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
    transient do
      managers { [] }
    end

    sequence(:name) { |n| "Managing Team #{n}" }

    after(:create) do |team, evaluator|
      if evaluator.managers.present?
        team.managers << evaluator.managers
      elsif team.managers.empty?
        team.managers << create(:user)
      end
    end
  end

  factory :responding_team, parent: :team do
    sequence(:name) { |n| "Responding Team #{n}" }
    responders { [create(:user)] }
  end

  factory :approving_team, parent: :team do
    sequence(:name) { |n| "Approving Team #{n}" }
    approvers { [create(:user)] }
  end

  factory :team_dacu, parent: :managing_team do
    name 'DACU'
    email 'dacu@localhost'

    initialize_with do
      Team.find_or_create_by(name: 'DACU', email: 'dacu@localhost')
    end
  end

  factory :team_dacu_disclosure, parent: :approving_team do
    name 'DACU Disclosure'
    email 'dacu.disclosure@localhost'
  end

  factory :team_press_office, parent: :approving_team do
    name 'Press Office'
    email 'press.office@localhost'
  end
end
