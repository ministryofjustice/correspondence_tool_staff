FactoryGirl.define do
  factory :business_unit do
    sequence(:name) { |n| "Business Unit #{n}" }
    email { Faker::Internet.email(name) }
    association :directorate
  end

  factory :managing_team, parent: :business_unit do
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

  factory :responding_team, parent: :business_unit do
    sequence(:name) { |n| "Responding Team #{n}" }
    responders { [create(:user)] }
  end

  factory :approving_team, parent: :business_unit do
    sequence(:name) { |n| "Approving Team #{n}" }
    approvers { [create(:user)] }
  end

  factory :team_dacu, parent: :managing_team do
    name 'DACU'
    email 'dacu@localhost'

    # initialize_with do
    #   BusinessUnit.find_or_create_by(name: 'DACU', email: 'dacu@localhost')
    # end
  end

  factory :team_dacu_disclosure, parent: :approving_team do
    name 'DACU Disclosure'
    email 'dacu.disclosure@localhost'
  end

  factory :team_press_office, parent: :approving_team do
    name 'Press Office'
    email 'press.office@localhost'
  end

  factory :team_private_office, parent: :approving_team do
    name 'Private Office'
    email 'private.office@localhost'
  end
end
