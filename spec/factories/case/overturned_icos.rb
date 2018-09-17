FactoryBot.define do

  factory :overturned_ico_sar,
          aliases: [:ot_ico_sar_noff_unassigned],
          class: Case::OverturnedICO::SAR do

    transient do
      creation_time   { 4.business_days.ago }
      identifier      { "unassigned overturned ico sar" }
    end

    message                         { identifier }
    current_state                   { 'unassigned' }
    original_ico_appeal             { create :ico_sar_case }
    original_case                   { create :sar_case }
    received_date                   { Date.yesterday }
    internal_deadline               { 10.days.from_now }
    external_deadline               { 20.days.from_now }
    escalation_deadline             { 3.days.from_now }
    reply_method                    { 'send_by_email' }
    email                           { 'dave@moj.com' }
    ico_officer_name                { 'Dan Dare' }
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

  factory :closed_ot_ico_sar, parent: :accepted_ot_ico_sar do

    missing_info              { false }

    transient do
      identifier { "closed overturned ico sar case" }
    end

    received_date { 4.business_days.ago }
    date_responded { 3.business_days.ago }

    after(:create) do |kase, evaluator|
      create :case_transition_respond,
             case: kase,
             acting_user_id: evaluator.responder.id,
             acting_team_id: evaluator.responding_team.id
      create :case_transition_close,
             case: kase,
             acting_user_id: evaluator.responder.id,
             acting_team_id: evaluator.responding_team.id
      kase.reload
    end
  end

  factory :overturned_ico_foi, aliases: [:ico_overturned_foi], class: Case::OverturnedICO::FOI do
    current_state                   { 'unassigned' }
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
