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

    factory :accepted_assignment, parent: :cases_teams_role do
      state 'accepted'
      user { create :responder }
    end
  end

end
