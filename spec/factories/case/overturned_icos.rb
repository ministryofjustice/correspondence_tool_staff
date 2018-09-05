FactoryBot.define do

  factory :overturned_ico_sar, class: Case::OverturnedICO::SAR do

    transient do
      creation_time   { 4.business_days.ago }
      identifier      { 'new overturned ico sar case' }
      managing_team   { find_or_create :team_dacu }
    end

    message                         { identifier }
    current_state                   { 'unassigned' }
    sequence(:ico_reference)        { |n| "ICO-SAR-1234-#{n}" }
    original_ico_appeal             { create :ico_sar_case }
    original_case                   { create :sar_case }
    received_date                   { Date.yesterday }
    internal_deadline               { 10.days.from_now }
    external_deadline               { 20.days.from_now }
    escalation_deadline             { 3.days.from_now }
    reply_method                    { 'send_by_email' }
    email                           { 'dave@moj.com' }
  end

  factory :awaiting_responder_overturned_ico_sar, parent: :overturned_ico_sar do
    transient do
      identifier      { "assigned overturned ico sar case" }
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


  factory :accepted_overturned_ico_sar, parent: :awaiting_responder_overturned_ico_sar do
    transient do
      identifier          { "accepted overturned ico sar case" }
      responder           { create :responder }
      responding_team     { responder.responding_teams.first }
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


  factory :overturned_ico_foi, class: Case::OverturnedICO::FOI do
    current_state                   { 'unassigned' }
    sequence(:ico_reference)        { |n| "ICO-FOI-1234-#{n}" }
    original_ico_appeal             { create :ico_foi_case }
    original_case                   { create :foi_case }
    received_date                   { Date.yesterday }
    internal_deadline               { 10.days.from_now }
    external_deadline               { 20.days.from_now }
    escalation_deadline             { 3.days.from_now }
    reply_method                    { 'send_by_email' }
    email                           { 'dave@moj.com' }
  end
end
