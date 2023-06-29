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
#  approved   :boolean          default(FALSE)
#

FactoryBot.define do
  factory :assignment do
    state { "pending" }
    team { create :responding_team }
    role { "responding" }
    association :case, factory: :case, strategy: :create

    factory :approver_assignment do
      transient do
        team_user { team.approvers.first }
      end

      team { create :approving_team }
      role { "approving" }

      factory :approved_assignment do
        approved { true }
      end
    end

    trait :responding do
      transient do
        team_user { team.responders.first }
      end

      team { create :responding_team }
      role { "responding" }
    end

    trait :managing do
      team { create :managing_team }
      role { "managing" }
    end

    trait :approving do
      team { create :approving_team }
      role { "approving" }
    end

    trait :accepted do
      state { "accepted" }
      user { team_user }
    end
  end
end
