FactoryBot.define do
  factory :overturned_ico_foi,
          aliases: [:ot_ico_foi_noff_unassigned],
          parent: :foi_case,
          class: "Case::OverturnedICO::FOI" do
    transient do
      creation_time { 4.business_days.ago }
      identifier    { "unassigned overturned ico foi" }
    end

    sequence(:message)  { |n| "#{identifier} message #{n}" }
    current_state       { "unassigned" }
    original_ico_appeal { create(:closed_ico_foi_case, :overturned_by_ico) }
    original_case       { original_ico_appeal.original_case }
    received_date       { Date.yesterday }
    internal_deadline   { 10.days.from_now }
    external_deadline   { 20.days.from_now }
    escalation_deadline { 3.days.from_now }
    ico_officer_name    { original_ico_appeal.ico_officer_name }
    reply_method        { original_case.sent_by_email? ? :send_by_email : :send_by_post }
    email               { original_case.email }
    postal_address      { original_case.postal_address }
  end

  factory :awaiting_responder_ot_ico_foi,
          aliases: [:ot_ico_foi_noff_awresp],
          parent: :overturned_ico_foi do
    transient do
      identifier      { "awaiting responder overturned ico foi case" }

      _state_taken_on_by_press_or_private { "awaiting_responder" }
      _state_taken_on_by_disclosure       { "awaiting_responder" }
    end

    created_at    { creation_time }
    received_date { creation_time }

    # Traits to bring in extra functionality
    _transition_to_awaiting_responder
    _taken_on_by_disclosure
    _taken_on_by_press_or_private_in_current_state

    after(:create, &:reload)
  end

  factory :accepted_ot_ico_foi,
          aliases: [:ot_ico_foi_noff_draft],
          parent: :awaiting_responder_ot_ico_foi do
    transient do
      identifier { "responder accepted overturned ico foi case" }

      _state_taken_on_by_press_or_private { "drafting" }
      _state_taken_on_by_disclosure       { "drafting" }
    end

    _transition_to_accepted
    _taken_on_by_disclosure
    _taken_on_by_press_or_private_in_current_state
  end

  factory :with_response_ot_ico_foi,
          parent: :accepted_ot_ico_foi do
    transient do
      identifier { "overturned ico foi case with response" }
      responses  do
        [build(:correspondence_response,
               type: "response",
               user_id: responder.id)]
      end
    end

    after(:create) do |kase, evaluator|
      kase.attachments.push(*evaluator.responses)

      create :case_transition_add_responses,
             case: kase,
             acting_team: evaluator.responding_team,
             acting_user: evaluator.responder,
             filenames: [evaluator.responses.map(&:filename)]
      kase.reload
    end
  end

  factory :pending_dacu_clearance_ot_ico_foi,
          parent: :accepted_ot_ico_foi do
    transient do
      identifier { "pending dacu clearance overturned ico foi case" }
    end

    flagged_accepted

    _transition_to_pending_dacu_clearance
  end

  factory :approved_trigger_ot_ico_foi,
          aliases: [:approved_disclosure_ot_ico_foi],
          parent: :pending_dacu_clearance_ot_ico_foi do
    transient do
      identifier { "approved by disclosure overturned ico foi case" }
      # date draft compliant is passed in in a transient blocked so it can is be
      # changed in the tests. It is added to the the case in the after create block
      # to match the order the code updates the case.
      date_draft_compliant { received_date + 2.days }
    end

    after(:create) do |kase, evaluator|
      kase.approver_assignments.for_team(evaluator.approving_team)
        .first.update!(approved: true)

      create :case_transition_approve,
             case: kase,
             acting_user: evaluator.approver,
             acting_team: evaluator.approving_team

      kase.assignments.approving.for_team(evaluator.approving_team)
        .update!(approved: true)

      kase.update!(date_draft_compliant: evaluator.date_draft_compliant)

      kase.reload
    end
  end

  factory :pending_press_clearance_ot_ico_foi,
          parent: :pending_dacu_clearance_ot_ico_foi do
    transient do
      identifier { "pending press clearance overturned ico foi case" }
    end

    taken_on_by_press
    flagged_accepted
    _transition_to_pending_press_clearance
  end

  factory :pending_private_clearance_ot_ico_foi,
          parent: :pending_press_clearance_ot_ico_foi do
    transient do
      identifier { "pending private clearance overturned ico foi case" }
    end

    _transition_to_pending_private_clearance
  end

  factory :approved_full_approval_ot_ico_foi,
          aliases: [:approved_press_private_ot_ico_foi],
          parent: :pending_private_clearance_ot_ico_foi do
    transient do
      identifier { "approved press private overturned ico foi case" }
      # date draft compliant is passed in in a transient blocked so it can is be
      # changed in the tests. It is added to the the case in the after create block
      # to match the order the code updates the case.
      date_draft_compliant { received_date + 2.days }
    end

    after(:create) do |kase, evaluator|
      kase.approver_assignments.for_team(evaluator.private_office)
        .first.update!(approved: true)

      create :case_transition_approve,
             case: kase,
             acting_user: evaluator.private_officer,
             acting_team: evaluator.private_office

      kase.assignments.approving.for_team(evaluator.private_office)
        .update!(approved: true)

      kase.reload
    end
  end

  factory :responded_ot_ico_foi,
          parent: :with_response_ot_ico_foi do
    transient do
      identifier { "responded overturned ico foi case" }
      responder { find_or_create :foi_responder }
    end

    date_responded { Time.zone.today }

    after(:create) do |kase, evaluator|
      create :case_transition_respond,
             case: kase,
             acting_user: evaluator.responder,
             acting_team: evaluator.responding_team
      kase.reload
    end
  end

  factory :responded_trigger_ot_ico_foi,
          aliases: [:responded_disclosure_approved_ot_ico_foi],
          parent: :approved_disclosure_ot_ico_foi do
    transient do
      identifier { "disclosure approved, responded overturned ico foi case" }
    end

    date_responded { Time.zone.today }

    after(:create) do |kase, evaluator|
      create :case_transition_respond,
             case: kase,
             acting_user: evaluator.responder,
             acting_team: evaluator.responding_team
      kase.reload
    end
  end

  factory :responded_full_approval_ot_ico_foi,
          aliases: [:responded_press_private_ot_ico_foi],
          parent: :approved_press_private_ot_ico_foi do
    transient do
      identifier { "press and private approved, responded overturned ico foi case" }
    end

    date_responded { Time.zone.today }

    after(:create) do |kase, evaluator|
      create :case_transition_respond,
             case: kase,
             acting_user: evaluator.responder,
             acting_team: evaluator.responding_team
      kase.reload
    end
  end

  factory :closed_ot_ico_foi, parent: :responded_ot_ico_foi do
    transient do
      identifier { "closed overturned ico foi case" }
    end

    received_date    { 4.business_days.ago }
    date_responded   { 3.business_days.ago }
    info_held_status { find_or_create :info_status, :held }
    outcome          { find_or_create :outcome, :granted }
    late_team_id     { responding_team }

    after(:create) do |kase, evaluator|
      create :case_transition_close,
             case: kase,
             acting_user: evaluator.manager,
             acting_team: evaluator.managing_team
      kase.reload
    end
  end

  factory :closed_trigger_ot_ico_foi,
          aliases: [:closed_disclosure_approved_ot_ico_foi],
          parent: :responded_trigger_ot_ico_foi do
    transient do
      identifier { "closed, approved trigger overturned ico foi case" }
    end

    received_date    { 4.business_days.ago }
    date_responded   { 2.business_days.ago }
    info_held_status { find_or_create :info_status, :held }
    outcome          { find_or_create :outcome, :granted }

    after(:create) do |kase, evaluator|
      create :case_transition_close,
             case: kase,
             acting_user: evaluator.manager,
             acting_team: evaluator.managing_team
      kase.reload
    end
  end

  factory :closed_full_approval_ot_ico_foi,
          aliases: [:closed_press_private_ot_ico_foi],
          parent: :responded_full_approval_ot_ico_foi do
    transient do
      identifier { "closed, approved full-approval overturned ico foi case" }
    end

    received_date    { 4.business_days.ago }
    date_responded   { 2.business_days.ago }
    info_held_status { find_or_create :info_status, :held }
    outcome          { find_or_create :outcome, :granted }

    after(:create) do |kase, evaluator|
      create :case_transition_close,
             case: kase,
             acting_user: evaluator.manager,
             acting_team: evaluator.managing_team
      kase.reload
    end
  end
end
