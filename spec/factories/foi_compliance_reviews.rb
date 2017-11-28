# == Schema Information
#
# Table name: cases
#
#  id                   :integer          not null, primary key
#  name                 :string
#  email                :string
#  message              :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  category_id          :integer
#  received_date        :date
#  postal_address       :string
#  subject              :string
#  properties           :jsonb
#  requester_type       :enum
#  number               :string           not null
#  date_responded       :date
#  outcome_id           :integer
#  refusal_reason_id    :integer
#  current_state        :string
#  last_transitioned_at :datetime
#  delivery_method      :enum
#  workflow             :string
#

FactoryGirl.define do

  factory :FOI_compliance_review, class: FOIComplianceReview do
    transient do
      creation_time { 4.business_days.ago }
      identifier "new case"
      managing_team { find_or_create :team_dacu }
    end

    requester_type 'member_of_the_public'
    sequence(:name) { |n| "#{identifier} name #{n}" }
    email { Faker::Internet.email(identifier) }
    # association :category, factory: :category, strategy: :create
    category
    delivery_method 'sent_by_email'
    sequence(:subject) { |n| "#{identifier} subject #{n}" }
    sequence(:message) { |n| "#{identifier} message #{n}" }
    received_date { Time.zone.today.to_s }
    sequence(:postal_address) { |n| "#{identifier} postal address #{n}" }
    created_at { creation_time }

    after(:build) do |_kase, evaluator|
      evaluator.managing_team
    end

    after(:create) do | kase, evaluator|
      ma = kase.managing_assignment
      ma.update! created_at: evaluator.creation_time
    end
  end

  factory :awaiting_responder_internal_review, parent: :FOI_compliance_review,
          aliases: [:d_case] do
    transient do
      identifier "assigned case"
      manager         { managing_team.managers.first }
      responding_team { create :responding_team }
    end

    created_at      { creation_time }
    received_date   { creation_time }

    after(:create) do |kase, evaluator|
      create :assignment,
             case: kase,
             team: evaluator.responding_team,
             state: 'pending',
             role: 'responding',
             created_at: evaluator.creation_time
      create :case_transition_assign_responder,
             case_id: kase.id,
             acting_user_id: evaluator.manager.id,
             acting_team_id: evaluator.managing_team.id,
             target_team_id: evaluator.responding_team.id,
             created_at: evaluator.creation_time
      kase.reload
    end
  end

  factory :accepted_internal_review, parent: :awaiting_responder_internal_review do
    transient do
      identifier "accepted case"
      responder { create :responder }
      responding_team { responder.responding_teams.first }
    end

    after(:create) do |kase, evaluator|
      kase.responder_assignment.update_attribute :user, evaluator.responder
      kase.responder_assignment.accepted!
      create :case_transition_accept_responder_assignment,
             case: kase,
             acting_user_id: kase.responder.id,
             acting_team_id: kase.responding_team.id,
             created_at: evaluator.creation_time
      kase.reload
    end
  end

  factory :internal_review_with_response, parent: :accepted_internal_review do
    transient do
      identifier "case with response"
      # creation_time { 4.business_days.ago }
      responder { find_or_create :responder, full_name: 'Ivor Response' }
      responses { [build(:correspondence_response, type: 'response', user_id: responder.id)] }
    end
  end

  factory :responded_internal_review, parent: :internal_review_with_response do
    transient do
      identifier "responded case"
      responder { create :responder }
    end

    date_responded Date.today

    after(:create) do |kase, evaluator|
      create :case_transition_respond,
             case: kase,
             acting_user_id: evaluator.responder.id,
             acting_team_id: evaluator.responding_team.id
      kase.reload
    end
  end
end
