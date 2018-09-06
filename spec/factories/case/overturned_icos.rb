FactoryBot.define do

  factory :overturned_ico_sar,
          aliases: [:ot_ico_sar_noff_unassigned],
          class: Case::OverturnedICO::SAR do
    transient do
      creation_time   { Time.now }
      # creation_time   { 4.business_days.ago }
      identifier      { "unassigned overturned ico sar" }
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

  factory :awaiting_responder_ot_ico_sar,
          aliases: [:ot_ico_sar_noff_awresp],
          parent: :overturned_ico_sar do

    transient do
      identifier      { "awaiting responder overturned ico sar case" }
      manager         { managing_team.managers.first }
      managing_team   { find_or_create :team_dacu }
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

  factory :accepted_ot_ico_sar,
          aliases: [:ot_ico_sar_noff_draft],
          parent: :awaiting_responder_ot_ico_sar do

    transient do
      identifier      { "responder accepted overturned ico sar case" }
      responder       { create :responder }
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

  factory :pending_dacu_clearance_to_ico_sar,
          aliases: [:ot_ico_sar_noff_pdacu],
          parent: :accepted_ot_ico_sar do
    transient do
      approving_team { find_or_create :team_dacu_disclosure }
      approver       { create :disclosure_specialist }
    end
    workflow { 'trigger' }

    after(:create) do |kase, evaluator|
      create :approver_assignment,
             case: kase,
             team: evaluator.approving_team,
             state: 'accepted',
             user_id: evaluator.approver.id

      create :case_transition_pending_dacu_clearance,
             case_id: kase.id,
             acting_user_id: evaluator.responder.id
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
