FactoryGirl.define do

  factory :sar_case,
          class: Case::SAR::NonOffender do
    transient do
      creation_time             { 4.business_days.ago }
      identifier                "new sar case"
      managing_team             { find_or_create :team_dacu }
    end

    current_state                 'unassigned'
    requester_type                'member_of_the_public'
    sequence(:name)               { |n| "#{identifier} name #{n}" }
    email                         { Faker::Internet.email(identifier) }
    delivery_method               'sent_by_email'
    sequence(:subject)            { |n| "#{identifier} subject #{n}" }
    sequence(:message)            { |n| "#{identifier} message #{n}" }
    received_date                 { Time.zone.today.to_s }
    sequence(:postal_address)     { |n| "#{identifier} postal address #{n}" }
    sequence(:subject_full_name)  { |n| "Subject #{n}" }
    subject_type                  'offender'
    third_party                   false
    created_at                    { creation_time }

    after(:build) do |_kase, evaluator|
      evaluator.managing_team
    end

    after(:create) do | kase, evaluator|
      ma = kase.managing_assignment
      ma.update! created_at: evaluator.creation_time
    end
  end

  factory :awaiting_responder_sar, parent: :sar_case, aliases: [:assigned_sar], class: Case::SAR::NonOffender do
    transient do
      identifier "assigned sar"
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

  factory :accepted_sar, parent: :assigned_sar,
          aliases: [:sar_being_drafted] do
    transient do
      identifier "accepted sar"
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
  factory :sar_with_response, parent: :accepted_sar do
    transient do
      identifier "sar with response"
      # creation_time { 4.business_days.ago }
      responder { find_or_create :responder, full_name: 'Ivor Response' }
      responses { [build(:correspondence_response, type: 'response', user_id: responder.id)] }
    end
    after(:create) do |kase, evaluator|
      kase.attachments.push(*evaluator.responses)

      create :case_transition_add_responses,
             case_id: kase.id,
             acting_team_id: evaluator.responding_team.id,
             acting_user_id: evaluator.responder.id
      # filenames: [evaluator.attachment.filename]
      kase.reload
    end
  end

  factory :responded_sar, parent: :sar_with_response do
    transient do
      identifier "responded sar"
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

  factory :closed_sar, parent: :responded_sar do

    info_held_status            { find_or_create :info_status, :held }
    outcome                     { find_or_create :outcome, :granted }
    message                     'info held, granted'

    transient do
      identifier "closed sar"
    end

    received_date { 22.business_days.ago }
    date_responded { 4.business_days.ago }

    after(:create) do |kase, evaluator|
      create :case_transition_close,
             case: kase,
             acting_user_id: evaluator.manager.id,
             acting_team_id: evaluator.managing_team.id,
             target_team_id: evaluator.responding_team.id
      kase.reload
    end
  end
end
