FactoryBot.define do

  sequence(:ico_foi_reference_number) { |n| "ICOFOIREFNUM%03d" % [n] }

  factory :ico_foi_case, class: Case::ICO::FOI do
    transient do
      creation_time { 4.business_days.ago }
      identifier    { "new ICO FOI case based from a closed FOI case" }
      managing_team { find_or_create :team_dacu }
      approving_team { find_or_create(:team_disclosure) }
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
    uploading_user              { find_or_create :manager }
    created_at                  { creation_time }

    after(:create) do |kase, evaluator|
      create :approver_assignment,
             case: kase,
             team: evaluator.approving_team,
             state: 'pending'
      create :flag_case_for_clearance_transition,
             case: kase,
             target_team_id: evaluator.approving_team.id
      kase.update(workflow: 'trigger')
    end

    trait :flagged_accepted do
      transient do
        approver       { approving_team.users.first }
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
      identifier        { "assigned ICO FOI case" }
      manager           { managing_team.managers.first }
      responding_team   { create :responding_team }
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

  factory :accepted_ico_foi_case, parent: :awaiting_responder_ico_foi_case do
    transient do
      identifier { "accepted ICO FOI case" }
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

  factory :pending_dacu_clearance_ico_foi_case, parent: :accepted_ico_foi_case do
    transient do
      identifier      { 'pending dacu clearance ICO FOI case' }
      approving_team  { find_or_create :team_dacu_disclosure }
      approver        { approving_team.users.first }
    end

    after(:create) do |kase, evaluator|
      kase.approver_assignments.for_team(evaluator.approving_team).singular
        .update_attributes(user: evaluator.approver,
                           state: 'accepted')
      create :case_transition_progress_for_clearance,
             case_id: kase.id,
             responding_team: evaluator.responding_team,
             responder: evaluator.responder
      kase.reload
    end
  end

  factory :approved_ico_foi_case, parent: :pending_dacu_clearance_ico_foi_case do
    transient do
      identifier { 'approved ICO FOI case' }
      approving_team { find_or_create :team_dacu_disclosure }
      approver { create :disclosure_specialist }
    end

    after(:create) do |kase, evaluator|
      create :case_transition_approve,
             case: kase,
             acting_team_id: evaluator.approving_team.id,
             acting_user_id: evaluator.approver.id

      kase.approver_assignments.each { |a| a.update approved: true }
      kase.reload
    end
  end

  factory :responded_ico_foi_case, parent: :approved_ico_foi_case do
    transient do
      identifier { 'responded ICO FOI case' }
    end

    date_responded { Date.today }

    after(:create) do |kase, _evaluator|
      create :case_transition_respond_to_ico,
             case_id: kase.id
      kase.reload
    end
  end

  factory :closed_ico_foi_case, parent: :responded_ico_foi_case do
    transient do
      identifier  { 'closed ICO FOI case' }
      attachments {[ build(:case_ico_decision) ]}
    end

    date_ico_decision_received { Date.today }
    ico_decision { "upheld" }

    trait :overturned_by_ico do
      ico_decision         { "overturned" }
      ico_decision_comment { Faker::NewGirl.quote }
    end

    after(:create) do |kase, evaluator|

      if kase.ico_decision == 'overturned'
        kase.attachments.push(*evaluator.attachments)
        kase.save!
      end

      create :case_transition_close_ico,
             case_id: kase.id
      kase.reload
    end
  end

end
