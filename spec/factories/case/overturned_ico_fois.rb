FactoryBot.define do

  factory :overturned_ico_foi,
          aliases: [:ot_ico_foi_noff_unassigned],
          class: Case::OverturnedICO::FOI do
    transient do
      creation_time { 4.business_days.ago }
      identifier    { "unassigned overturned ico foi" }
    end

    sequence(:message)  { |n| "#{identifier} message #{n}" }
    current_state       { 'unassigned' }
    original_ico_appeal { create :closed_ico_foi_case }
    original_case       { create :foi_case }
    received_date       { Date.yesterday }
    internal_deadline   { 10.days.from_now }
    external_deadline   { 20.days.from_now }
    escalation_deadline { 3.days.from_now }
    ico_officer_name    { original_ico_appeal.ico_officer_name }
    reply_method        { original_case.sent_by_email? ? :send_by_email : :send_by_post  }
    email               { original_case.email }
    postal_address      { original_case.postal_address }

    after(:create) do | kase, evaluator|
      ma = kase.managing_assignment
      ma.update! created_at: evaluator.creation_time
    end
  end

  factory :awaiting_responder_ot_ico_foi,
          aliases: [:ot_ico_foi_noff_awresp],
          parent: :overturned_ico_foi do

    transient do
      identifier      { "awaiting responder overturned ico foi case" }
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

  factory :accepted_ot_ico_foi,
          aliases: [:ot_ico_foi_noff_draft],
          parent: :awaiting_responder_ot_ico_foi do

    transient do
      identifier      { "responder accepted overturned ico foi case" }
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

  factory :with_response_ot_ico_foi, parent: :accepted_ot_ico_foi do
    transient do
      identifier { "case with response" }
      responder { find_or_create :responder, full_name: 'Ivor Response' }
      responses { [build(:correspondence_response, type: 'response', user_id: responder.id)] }
    end

    after(:create) do |kase, evaluator|
      kase.attachments.push(*evaluator.responses)

      create :case_transition_add_responses,
             case_id: kase.id,
             acting_team_id: evaluator.responding_team.id,
             acting_user_id: evaluator.responder.id
      kase.reload
    end
  end

  factory :responded_ot_ico_foi, parent: :with_response_ot_ico_foi do
    transient do
      identifier { "responded case" }
      responder { create :responder }
    end

    date_responded { Date.today }

    after(:create) do |kase, evaluator|
      create :case_transition_respond,
             case: kase,
             acting_user_id: evaluator.responder.id,
             acting_team_id: evaluator.responding_team.id,
             target_user_id: evaluator.responder.id,
             target_team_id: evaluator.responding_team.id
      kase.reload
    end
  end

  factory :closed_ot_ico_foi, parent: :accepted_ot_ico_foi do

    transient do
      identifier { "closed overturned ico foi case" }
    end

    received_date    { 4.business_days.ago }
    date_responded   { 3.business_days.ago }
    info_held_status { find_or_create :info_status, :held }
    outcome          { find_or_create :outcome, :granted }

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
end
