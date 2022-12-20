FactoryBot.define do

  sequence(:ico_foi_reference_number) { |n| "ICOFOIREFNUM%03d" % [n] }

  factory :ico_foi_case, class: Case::ICO::FOI do
    transient do
      creation_time  { 4.business_days.ago }
      identifier     { "new ICO FOI case based from a closed FOI case" }
      managing_team  { find_or_create :team_dacu }

      flag_for_disclosure { :pending }
      approving_team { find_or_create(:team_disclosure) }
      approver       { find_or_create(:disclosure_specialist) }
    end

    current_state               { 'unassigned' }
    sequence(:message)          { |n| "#{identifier} message #{n}" }
    ico_reference_number        { generate :ico_foi_reference_number }
    sequence(:ico_officer_name) { |n| "#{identifier} ico officer name #{n}" }
    association :original_case, factory: :closed_case
    received_date               { 0.business_days.ago }
    external_deadline           { 20.business_days.after(received_date) }
    internal_deadline           { 10.business_days.before(external_deadline) }
    uploaded_request_files      { ["#{Faker::Internet.slug}.pdf"] }
    creator                     { find_or_create :manager }
    created_at                  { creation_time }

    after(:create) do |kase, evaluator|
      create :approver_assignment,
             case: kase,
             team: evaluator.approving_team,
             state: 'pending'
      create :flag_case_for_clearance_transition,
             case: kase,
             acting_team: evaluator.managing_team,
             acting_user: evaluator.managing_team.managers.first,
             target_team: evaluator.approving_team
      kase.update(workflow: 'trigger')

      if evaluator.flag_for_disclosure == :accepted
        disclosure_assignment = kase.assignments.for_team(
          evaluator.approving_team
        ).singular
        disclosure_assignment.update(state: 'accepted',
                                     user: evaluator.approver)
      end

      kase.reload
    end

    trait :flagged_accepted do
      transient do
        approver { approving_team.users.first }
      end

      after(:create) do |kase, evaluator|
        kase.assignments.for_team(evaluator.approving_team).first.update(
          state: 'accepted',
          user_id: evaluator.approver.id,
        )
        create :flag_case_for_clearance_transition,
               case: kase,
               target_team_id: evaluator.approving_team.id
      end
    end
  end

  factory :awaiting_responder_ico_foi_case, parent: :ico_foi_case do
    transient do
      identifier      { "assigned ICO FOI case" }
      manager         { managing_team.managers.first }
      responding_team { original_case.responding_team }
    end

    created_at    { creation_time }
    received_date { creation_time }

    after(:create) do |kase, evaluator|
      create :assignment,
             case: kase,
             team: evaluator.responding_team,
             state: 'pending',
             role: 'responding',
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

  factory :accepted_ico_foi_case, parent: :awaiting_responder_ico_foi_case do
    transient do
      identifier { "accepted ICO FOI case" }
      responder  { responding_team.responders.first }
    end

    after(:create) do |kase, evaluator|
      kase.responder_assignment.update_attribute :user, evaluator.responder
      kase.responder_assignment.accepted!
      create :case_transition_accept_responder_assignment,
             case: kase,
             acting_user: kase.responder,
             acting_team: kase.responding_team,
             created_at: evaluator.creation_time
      kase.reload
    end
  end


  factory :ico_foi_case_with_response, parent: :accepted_ico_foi_case do
    transient do
      identifier { "ico foi case with response" }
      responses { [build(:correspondence_response, type: 'response', user_id: responder.id)] }
    end

    after(:create) do |kase, evaluator|
      kase.attachments.push(*evaluator.responses)

      create :case_transition_add_responses,
             case: kase,
             acting_team: kase.responding_team,
             acting_user: kase.responder,
             filenames: [evaluator.responses.map(&:filename)]
      kase.reload
    end
  end

  factory :pending_dacu_clearance_ico_foi_case, parent: :accepted_ico_foi_case do
    transient do
      identifier      { 'pending dacu clearance ICO FOI case' }
    end

    after(:create) do |kase, evaluator|
      kase.approver_assignments.for_team(evaluator.approving_team).singular
        .update(user: evaluator.approver, state: 'accepted')
      create :case_transition_pending_dacu_clearance,
             case: kase,
             acting_team: evaluator.responding_team,
             acting_user: evaluator.responder,
             target_team: evaluator.approving_team
      kase.reload
    end
  end

  factory :approved_ico_foi_case, parent: :pending_dacu_clearance_ico_foi_case do
    transient do
      identifier { 'approved ICO FOI case' }
# date draft compliant is passed in in a transient blocked so it can is be
# changed in the tests. It is added to the the case in the after create block
# to match the order the code updates the case.
      date_draft_compliant { received_date + 2.days }
    end

    after(:create) do |kase, evaluator|
      create :case_transition_approve,
             case: kase,
             acting_team: evaluator.approving_team,
             acting_user: evaluator.approver

      kase.approver_assignments.each { |a| a.update approved: true }
      kase.update!(date_draft_compliant: evaluator.date_draft_compliant)
      kase.reload
    end
  end

  factory :responded_ico_foi_case, parent: :approved_ico_foi_case do
    transient do
      identifier { 'responded ICO FOI case' }
  # date draft compliant is passed in in a transient blocked so it can is be
  # changed in the tests. It is added to the the case in the after create block
  # to match the order the code updates the case.
      date_draft_compliant { received_date + 2.days }
    end

    date_responded { Date.today }

    after(:create) do |kase, evaluator|
      create :case_transition_respond_to_ico,
             case: kase
      kase.update!(date_draft_compliant: evaluator.date_draft_compliant)
      kase.reload
    end
  end

  factory :awaiting_dispatch_ico_foi_case, parent: :approved_ico_foi_case do
    transient do
      identifier { 'awaiting dispatch ICO FOI case' }
  # date draft compliant is passed in in a transient blocked so it can is be
  # changed in the tests. It is added to the the case in the after create block
  # to match the order the code updates the case.
      date_draft_compliant { received_date + 2.days }
    end

    date_responded { Date.today }

    after(:create) do |kase, evaluator|
      create :case_transition_await_dispatch_ico,
             case: kase
      kase.update!(date_draft_compliant: evaluator.date_draft_compliant)
      kase.reload
    end
  end

  factory :closed_ico_foi_case, parent: :responded_ico_foi_case do
    transient do
      identifier  { 'closed ICO FOI case' }
      attachments {[ build(:case_ico_decision) ]}
    end

    received_date { 22.business_days.ago }
    date_ico_decision_received { 4.business_days.ago }
    ico_decision { "upheld" }
    late_team_id { responding_team.id }

    trait :overturned_by_ico do
      ico_decision         { "overturned" }
      ico_decision_comment { Faker::TvShows::DrWho.quote }

    end

    after(:create) do |kase, evaluator|
      kase.attachments.push(*evaluator.attachments)
      kase.save!
      create :case_transition_close_ico, case: kase
      kase.reload
    end
  end

  factory :require_further_action_ico_foi_case, parent: :responded_ico_foi_case do
    transient do
      identifier { 'ICO FOI case required further action' }
    end

    after(:create) do |kase, evaluator|
      create :case_transition_require_further_action,
             case: kase
      kase.update!(
        original_external_deadline: kase.external_deadline,
        original_internal_deadline: kase.internal_deadline,
        original_date_responded: kase.date_responded
      )
      kase.reload
      kase.update!(
        external_deadline: 20.business_days.after(evaluator.original_external_deadline),
        internal_deadline: 10.business_days.after(evaluator.original_external_deadline),
        date_responded: nil
      )
      kase.reload
    end
  end

end
