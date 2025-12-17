FactoryBot.define do
  factory :offender_sar_case, class: "Case::SAR::Offender" do
    transient do
      creation_time       { 4.business_days.ago }
      identifier          { "New Offender SAR case" }
      managing_team       { find_or_create :team_branston }
      manager             { managing_team.managers.first }
      responding_team     { find_or_create :team_branston }
      responder           { responding_team.responders.first }

      approving_team      { find_or_create :team_branston }
      approver            { approving_team.approvers.first }
      i_am_deleted        { false }
    end

    current_state                   { "data_to_be_requested" }
    sequence(:name)                 { |n| "#{identifier} name #{n}" }
    email                           { Faker::Internet.email(name: identifier) }
    sequence(:subject)              { |n| "#{identifier} subject #{n}" }
    sequence(:message)              { |n| "#{identifier} message #{n}" }
    received_date                   { Time.zone.today.to_s }
    date_of_birth                   { Time.zone.today.to_s }
    sequence(:postal_address)       { |n| "#{identifier} postal address #{n}" }
    sequence(:subject_full_name)    { |n| "Subject #{n}" }
    sequence(:subject_aliases)      { |n| "#{identifier} subject alias #{n}" }
    previous_case_numbers           { "54321" }
    prison_number                   { "123465" }
    probation_area                  { "Smallville" }
    other_subject_ids               { "ABC 123 DEF" }
    case_reference_number           { "123 ABC 456" }
    subject_address                 { "22 Sample Address, Test Lane, Testingington, TE57ST" }
    request_dated                   { Date.parse("13-07-2010") }
    request_method                  { "email" }
    requester_reference             { "456 ABC 123" }
    subject_type                    { "offender" }
    recipient                       { "subject_recipient" }
    third_party                     { false }
    flag_as_high_profile            { false }
    flag_as_dps_missing_data        { false }
    created_at                      { creation_time }
    creator                         { create(:user, :orphan) }
    number_final_pages              { 5 }
    number_exempt_pages             { 2 }
    is_partial_case                 { false }
    further_actions_required        { "no" }
  end

  trait :third_party do
    third_party { true }
    third_party_relationship { "Solicitor" }
    requester_reference { "FOOG1234" }
    third_party_company_name { "Foogle and Sons Solicitors at Law" }
    third_party_name { "Mr J. Smith" }
    postal_address { "22 High Street" }
    recipient { "requester_recipient" }
    third_party_email { "foogle@solicitors.com" }
  end

  trait :rejected do
    current_state { "invalid_submission" }
    rejected_reasons { %w[further_identification court_data_request] }
    flag_as_dps_missing_data { false }
  end

  trait :invalid_submission do
    rejected
  end

  trait :data_to_be_requested do
    # Default state for a new offender_sar_case
  end

  trait :waiting_for_data do
    transient do
      identifier { "Waiting for data Offender SAR" }
    end

    after(:create) do |kase|
      create :case_transition_waiting_for_data, case: kase
      kase.reload
    end
  end

  trait :ready_for_vetting do
    transient do
      identifier { "Ready for vetting Offender SAR" }
    end

    after(:create) do |kase|
      create :case_transition_waiting_for_data, case: kase
      create :case_transition_ready_for_vetting, case: kase
      kase.reload
    end
  end

  trait :vetting_in_progress do
    transient do
      identifier { "Vetting in progress Offender SAR" }
    end

    after(:create) do |kase|
      create :case_transition_waiting_for_data, case: kase
      create :case_transition_ready_for_vetting, case: kase
      create :case_transition_vetting_in_progress, case: kase
      kase.assignments.create!(team: kase.responding_team, role: "responding")
      kase.responder_assignment.update!(user: kase.responding_team.users.first)
      kase.responder_assignment.accepted!
      kase.reload
    end
  end

  trait :ready_to_copy do
    transient do
      identifier { "Ready to close Offender SAR" }
    end

    after(:create) do |kase|
      create :case_transition_waiting_for_data, case: kase
      create :case_transition_ready_for_vetting, case: kase
      create :case_transition_vetting_in_progress, case: kase
      create :case_transition_ready_to_copy, case: kase
      kase.reload
    end
  end

  trait :ready_to_dispatch do
    date_responded { Time.zone.today }
    info_held_status { find_or_create :info_status, :held }
    transient do
      identifier { "Ready to dispatch Offender SAR" }
    end

    after(:create) do |kase|
      create :case_transition_waiting_for_data, case: kase
      create :case_transition_ready_for_vetting, case: kase
      create :case_transition_vetting_in_progress, case: kase
      create :case_transition_ready_to_copy, case: kase
      create :case_transition_ready_to_dispatch, case: kase
      kase.reload
    end
  end

  trait :closed do
    transient do
      identifier { "Closed Offender SAR" }
    end

    received_date  { 22.business_days.ago }
    date_responded { 4.business_days.ago }

    after(:create) do |kase|
      create :case_transition_waiting_for_data, case: kase
      create :case_transition_ready_for_vetting, case: kase
      create :case_transition_vetting_in_progress, case: kase
      create :case_transition_ready_to_copy, case: kase
      create :case_transition_ready_to_dispatch, case: kase
      create :case_transition_closed_for_offender_sar_type, case: kase
      kase.reload
    end
  end

  trait :with_retention_schedule do
    transient do
      planned_destruction_date { Time.zone.today }
      state {}
    end

    after(:create) do |kase, evaluator|
      kase.retention_schedule = RetentionSchedule.new(
        planned_destruction_date: evaluator.planned_destruction_date, state: evaluator.state,
      )
      kase.save!
    end
  end

  trait :flag_as_dps_missing_data do
    flag_as_dps_missing_data { true }
  end

  trait :stopped do
    after(:create) do |kase, evaluator|
      create :case_transition_stop_the_clock, case: kase, acting_user: evaluator.manager
    end
  end
end
