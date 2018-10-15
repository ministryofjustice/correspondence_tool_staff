FactoryBot.define do

  factory :sar_case,
          class: Case::SAR do
    transient do
      creation_time             { 4.business_days.ago }
      identifier                { "new sar case" }
      managing_team             { find_or_create :team_dacu }
    end

    current_state                 { 'unassigned' }
    sequence(:name)               { |n| "#{identifier} name #{n}" }
    email                         { Faker::Internet.email(identifier) }
    reply_method                  { 'send_by_email' }
    sequence(:subject)            { |n| "#{identifier} subject #{n}" }
    sequence(:message)            { |n| "#{identifier} message #{n}" }
    received_date                 { Time.zone.today.to_s }
    sequence(:postal_address)     { |n| "#{identifier} postal address #{n}" }
    sequence(:subject_full_name)  { |n| "Subject #{n}" }
    subject_type                  { 'offender' }
    third_party                   { false }
    created_at                    { creation_time }

    trait :third_party do
      third_party { true }
      third_party_relationship { 'Aunt' }
    end

    before(:create) do
      # puts "   SAR before  create  unassigned Teams: #{Team.count}  Users: #{User.count}"
    end

    after(:build) do |_kase, evaluator|
      evaluator.managing_team
      # puts "   SAR after  build  unassigned Teams: #{Team.count}  Users: #{User.count}"
    end

    after(:create) do | kase, evaluator|
      ma = kase.managing_assignment
      ma.update! created_at: evaluator.creation_time
      # puts "   SAR after  create unassigned Teams: #{Team.count}  Users: #{User.count}"
    end
  end

  factory :awaiting_responder_sar,
          parent: :sar_case,
          aliases: [:assigned_sar],
          class: Case::SAR do
    transient do
      identifier { "assigned sar" }
      manager         { managing_team.managers.first }
      responding_team { find_or_create :sar_responding_team }
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
             case: kase,
             acting_user: evaluator.manager,
             acting_team: evaluator.managing_team,
             target_team: evaluator.responding_team,
             created_at: evaluator.creation_time
      kase.reload
      # puts "   SAR after  create awaiting Teams: #{Team.count}  Users: #{User.count}"
    end
  end

  factory :accepted_sar, parent: :assigned_sar,
          aliases: [:sar_being_drafted] do
    transient do
      identifier { "accepted sar" }
      responder { responding_team.responders.first }
    end

    after(:create) do |kase, evaluator|
      responder = evaluator.responder || responding_team.responders.first
      kase.responder_assignment.update_attribute :user, responder
      kase.responder_assignment.accepted!
      create :case_transition_accept_responder_assignment,
             case: kase,
             acting_user: kase.responder,
             acting_team: kase.responding_team,
             created_at: evaluator.creation_time
      kase.reload
      # puts "   SAR after  create accepted Teams: #{Team.count}  Users: #{User.count}"
    end
  end

  factory :pending_dacu_clearance_sar, parent: :accepted_sar do
    transient do
      approving_team { find_or_create :team_dacu_disclosure }
      approver       { find_or_create :disclosure_specialist }
    end
    workflow { 'trigger' }

    after(:create) do |kase, evaluator|
      create :approver_assignment,
             case: kase,
             team: evaluator.approving_team,
             state: 'accepted',
             user: evaluator.approver

      create :case_transition_pending_dacu_clearance,
             case: kase,
             acting_user: evaluator.responder
      kase.reload
      # puts "   SAR after  create pending Teams: #{Team.count}  Users: #{User.count}"
    end
  end

  factory :approved_sar, parent: :pending_dacu_clearance_sar do
    after(:create) do |kase, evaluator|
      create :case_transition_approve,
             case: kase,
             acting_team: evaluator.approving_team,
             acting_user: evaluator.approver

      kase.approver_assignments.each { |a| a.update approved: true }
      kase.reload
      # puts "   SAR after  create approved Teams: #{Team.count}  Users: #{User.count}"
    end
  end

  factory :closed_trigger_sar, parent: :approved_sar do

    missing_info              { false }

    transient do
      identifier { "closed sar" }
    end

    received_date { 22.business_days.ago }
    date_responded { 4.business_days.ago }

    after(:create) do |kase, evaluator|
      create :case_transition_respond,
             case: kase,
             acting_user: evaluator.responder,
             acting_team: evaluator.responding_team
      create :case_transition_close,
             case: kase,
             acting_user: evaluator.manager,
             acting_team: evaluator.managing_team,
             target_team: evaluator.responding_team
      kase.reload
      # puts "   SAR trigger after  create closed  Teams: #{Team.count}  Users: #{User.count}"
    end
  end

  factory :closed_sar, parent: :accepted_sar do

    missing_info              { false }

    transient do
      identifier { "closed sar" }
    end

    received_date { 22.business_days.ago }
    date_responded { 4.business_days.ago }

    after(:create) do |kase, evaluator|
      create :case_transition_respond,
             case: kase,
             acting_user: evaluator.responder,
             acting_team: evaluator.responding_team,
             target_user: evaluator.responder,
             target_team: evaluator.responding_team
      create :case_transition_close,
             case: kase,
             acting_user: evaluator.manager,
             acting_team: evaluator.managing_team,
             target_team: evaluator.responding_team
      kase.reload
      # puts "   SAR after  create closed  Teams: #{Team.count}  Users: #{User.count}"
    end
  end

  trait :clarification_required do
    refusal_reason              { find_or_create :refusal_reason, :tmm }
    missing_info                { true }
    message                     { 'info held other, clarification required' }
  end

end
