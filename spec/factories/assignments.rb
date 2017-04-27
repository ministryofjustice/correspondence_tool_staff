# == Schema Information
#
# Table name: assignments
#
#  id         :integer          not null, primary key
#  state      :enum             default("pending")
#  case_id    :integer          not null
#  team_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  role       :enum
#  user_id    :integer
#

FactoryGirl.define do

  factory :assignment do
    state 'pending'
    team { create :responding_team }
    role 'responding'
    association :case, factory: :case, strategy: :create

    trait :approving do
      transient do
        team_user { team.approvers.first }
      end

      team { create :approving_team }
      role 'approving'
    end

    trait :responding do
      transient do
        team_user { team.responders.first }
      end

      team { create :approving_team }
      role 'approving'
    end

    trait :accepted do
      state 'accepted'
      user team_user
    end
  end

end
