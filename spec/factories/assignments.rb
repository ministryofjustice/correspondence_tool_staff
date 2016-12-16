FactoryGirl.define do

  factory :assignment do
    assignment_type 'drafter'
    state 'pending'
    association :assigner, factory: :user, strategy: :create
    association :assignee, factory: :user, strategy: :create
    association :case, factory: :case, strategy: :create
  end

end
