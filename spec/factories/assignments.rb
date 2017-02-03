# == Schema Information
#
# Table name: assignments
#
#  id              :integer          not null, primary key
#  assignment_type :enum
#  state           :enum             default("pending")
#  case_id         :integer
#  assignee_id     :integer
#  assigner_id     :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

FactoryGirl.define do

  factory :assignment do
    assignment_type 'drafter'
    state 'pending'
    association :assigner, factory: :assigner, strategy: :create
    association :assignee, factory: :drafter, strategy: :create
    association :case, factory: :case, strategy: :create
  end

end
