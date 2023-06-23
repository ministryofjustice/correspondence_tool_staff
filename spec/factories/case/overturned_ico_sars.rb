FactoryBot.define do
  factory :overturned_ico_sar,
          aliases: [:ot_ico_sar_noff_unassigned],
          class: "Case::OverturnedICO::SAR" do
    transient do
      creation_time   { 4.business_days.ago }
      identifier      { "unassigned overturned ico sar" }
      managing_team   { find_or_create :team_disclosure_bmt }
      manager         { managing_team.managers.first }
      approving_team  { find_or_create :team_disclosure }
      approver        { approving_team.approvers.first }
      responding_team { find_or_create :sar_responding_team }
      responder       { find_or_create :sar_responder }
    end

    message             { identifier }
    current_state       { "unassigned" }
    original_ico_appeal { create(:closed_ico_sar_case, :overturned_by_ico) }
    original_case       { original_ico_appeal.original_case }
    received_date       { Time.zone.yesterday }
    internal_deadline   { 10.days.from_now }
    external_deadline   { 20.days.from_now }
    escalation_deadline { 3.days.from_now }
    reply_method        { "send_by_email" }
    email               { "dave@moj.com" }
    ico_officer_name    { "Dan Dare" }
    creator             { create(:user, :orphan) }

    trait :flagged do
      after(:create) do |kase, evaluator|
        create :approver_assignment,
               case: kase,
               team: evaluator.approving_team,
               state: "pending"
        create :flag_case_for_clearance_transition,
               case: kase,
               acting_team: evaluator.managing_team,
               acting_user: evaluator.manager,
               target_team: evaluator.approving_team,
               to_workflow: "trigger"
        kase.update!(workflow: "trigger")
        kase.reload
      end
    end

    trait :flagged_accepted do
      after(:create) do |kase, evaluator|
        create :approver_assignment,
               case: kase,
               user: evaluator.approver,
               team: evaluator.approving_team,
               state: "accepted"
        create :flag_case_for_clearance_transition,
               case: kase,
               acting_team: evaluator.managing_team,
               acting_user: evaluator.manager,
               target_team: evaluator.approving_team,
               to_workflow: "trigger"
        create :case_transition_accept_approver_assignment,
               case: kase,
               acting_team: evaluator.approving_team,
               acting_user: evaluator.approver
        kase.update!(workflow: "trigger")
        kase.reload
      end
    end
  end

  factory :awaiting_responder_ot_ico_sar,
          aliases: [:ot_ico_sar_noff_awresp],
          parent: :overturned_ico_sar do
    transient do
      identifier { "awaiting responder overturned ico sar case" }
    end

    created_at    { creation_time }
    received_date { creation_time }

    after(:create) do |kase, evaluator|
      create :assignment,
             case: kase,
             team: evaluator.responding_team,
             state: "pending",
             role: "responding",
             created_at: evaluator.creation_time
      create :case_transition_assign_responder,
             case: kase,
             acting_user: evaluator.manager,
             acting_team: evaluator.managing_team,
             target_team: evaluator.responding_team,
             created_at: evaluator.creation_time
      kase.reload
    end
  end

  factory :accepted_ot_ico_sar,
          aliases: [:ot_ico_sar_noff_draft],
          parent: :awaiting_responder_ot_ico_sar do
    transient do
      identifier { "responder accepted overturned ico sar case" }
    end

    after(:create) do |kase, evaluator|
      kase.responder_assignment.update!(user: evaluator.responder)
      kase.responder_assignment.accepted!
      create :case_transition_accept_responder_assignment,
             case: kase,
             acting_user: kase.responder,
             acting_team: kase.responding_team,
             created_at: evaluator.creation_time
      kase.reload
    end
  end

  factory :closed_ot_ico_sar, parent: :accepted_ot_ico_sar do
    missing_info { false }

    transient do
      identifier { "closed overturned ico sar case" }
    end

    received_date { 4.business_days.ago }
    date_responded { 3.business_days.ago }

    after(:create) do |kase, evaluator|
      create :case_transition_respond,
             case: kase,
             acting_user: evaluator.responder,
             acting_team: evaluator.responding_team
      create :case_transition_close,
             case: kase,
             acting_user: evaluator.responder,
             acting_team: evaluator.responding_team
      kase.reload
    end
  end

  factory :pending_dacu_clearance_ot_ico_sar, parent: :accepted_ot_ico_sar do
    transient do
      identifier { "pending dacu clearance ICO SAR case" }
    end
    workflow { "trigger" }

    after(:create) do |kase, evaluator|
      create :case_transition_progress_for_clearance,
             case: kase,
             acting_team: evaluator.responding_team,
             acting_user: evaluator.responder,
             target_team: evaluator.approving_team
      kase.reload
    end
  end

  factory :awaiting_dispatch_ot_ico_sar, parent: :pending_dacu_clearance_ot_ico_sar do
    transient do
      identifier { "awaiting dispatch ICO SAR case" }
      # date draft compliant is passed in in a transient blocked so it can is be
      # changed in the tests. It is added to the the case in the after create block
      # to match the order the code updates the case.
      date_draft_compliant { received_date + 2.days }
    end

    workflow { "trigger" }

    after(:create) do |kase, evaluator|
      create :case_transition_approve,
             case: kase,
             acting_team: evaluator.approving_team,
             acting_user: evaluator.approver
      kase.update!(date_draft_compliant: evaluator.date_draft_compliant)
      kase.current_state = "awaiting_dispatch"
    end
  end
end
