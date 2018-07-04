FactoryBot.define do

  sequence(:ico_foi_reference_number) { |n| "ICOFOIREFNUM%03d" % [n] }

  factory :ico_foi_case, class: Case::ICO::FOI do
    transient do
      creation_time   { 4.business_days.ago }
      identifier      "new ICO FOI case"
      managing_team   { find_or_create :team_dacu }
    end

    current_state          'unassigned'
    sequence(:name)        { |n| "#{identifier} name #{n}" }
    sequence(:subject)     { |n| "#{identifier} subject #{n}" }
    sequence(:message)     { |n| "#{identifier} message #{n}" }
    ico_reference_number   { generate :ico_foi_reference_number }
    received_date          { 0.business_days.from_now }
    external_deadline      { 20.business_days.from_now.to_date }
    uploaded_request_files { ["#{Faker::Internet.slug}.pdf"] }
    uploading_user         { find_or_create :manager }
    created_at             { creation_time }
  end

  factory :awaiting_responder_ico_foi_case, parent: :ico_foi_case do
    transient do
      identifier        "assigned ICO FOI case"
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
      identifier "accepted ICO FOI case"
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

end

