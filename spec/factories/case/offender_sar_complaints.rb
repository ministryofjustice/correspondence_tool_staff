FactoryBot.define do
  factory :offender_sar_complaint, class: "Case::SAR::OffenderComplaint" do
    transient do
      creation_time       { 4.business_days.ago }
      identifier          { "New Offender SAR complaint" }
      managing_team       { find_or_create :team_branston }
      manager             { managing_team.managers.first }
      responding_team     { find_or_create :team_branston }
      responder           { responding_team.responders.first }

      approving_team      { find_or_create :team_branston }
      approver            { approving_team.approvers.first }
      i_am_deleted        { false }
    end

    current_state { "to_be_assessed" }
    association :original_case, factory: %i[offender_sar_case closed]
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
    requester_reference             { "456 ABC 123" }
    subject_type                    { "offender" }
    request_method                  { "email" }
    recipient                       { "subject_recipient" }
    complaint_type                  { "standard_complaint" }
    complaint_subtype               { "missing_data" }
    priority                        { "normal" }
    ico_contact_name                { "Bob ico contact" }
    ico_contact_email               { "bob-ico-contact@example.com" }
    ico_contact_phone               { "020 123 4567" }
    ico_reference                   { "ico-ref-001" }
    gld_contact_name                { "Jha gld contact" }
    gld_contact_email               { "jha-gld-contact@example.com" }
    gld_contact_phone               { "020 456 1234" }
    gld_reference                   { "gld-ref-001" }
    third_party                     { false }
    flag_as_high_profile            { false }
    flag_as_dps_missing_data        { false }
    created_at                      { creation_time }
    creator                         { responder }
    external_deadline               { Time.zone.today + 20.days }
    number_final_pages              { 5 }
    number_exempt_pages             { 2 }
    settlement_cost                 { 0 }
    total_cost                      { 0 }

    trait :third_party_complaint do
      third_party { true }
      third_party_relationship { "Solicitor" }
      requester_reference { "FOOG1234" }
      third_party_company_name { "Foogle and Sons Solicitors at Law" }
      third_party_name { "Mr J. Smith" }
      postal_address { "22 High Street" }
      recipient { "requester_recipient" }
    end

    trait :to_be_assessed do
      # Default state for a new offender_sar_complaint
    end

    trait :data_review_required do
      transient do
        identifier { "Data review required - Complaint" }
      end

      after(:create) do |kase|
        create :case_transition_data_review_required, case: kase
        kase.reload
      end
    end

    trait :data_to_be_requested do
      transient do
        identifier { "Data to be requested - Offender SAR Complaint" }
      end

      after(:create) do |kase|
        create :case_transition_data_to_be_requested, case: kase
        kase.reload
      end
    end

    trait :waiting_for_data do
      transient do
        identifier { "Waiting for data - Offender SAR Complaint" }
      end

      after(:create) do |kase|
        create :case_transition_data_to_be_requested, case: kase
        create :case_transition_waiting_for_data, case: kase
        kase.reload
      end
    end

    trait :ready_for_vetting do
      transient do
        identifier { "Ready for vetting - Offender SAR Complaint" }
      end

      after(:create) do |kase|
        create :case_transition_data_to_be_requested, case: kase
        create :case_transition_waiting_for_data, case: kase
        create :case_transition_ready_for_vetting, case: kase
        kase.reload
      end
    end

    trait :vetting_in_progress do
      transient do
        identifier { "Vetting in progress - Offender SAR Complaint" }
      end

      after(:create) do |kase|
        create :case_transition_data_to_be_requested, case: kase
        create :case_transition_waiting_for_data, case: kase
        create :case_transition_ready_for_vetting, case: kase
        create :case_transition_vetting_in_progress, case: kase
        kase.reload
      end
    end

    trait :ready_to_copy do
      transient do
        identifier { "Ready to close - Offender SAR Complaint" }
      end

      after(:create) do |kase|
        create :case_transition_data_to_be_requested, case: kase
        create :case_transition_waiting_for_data, case: kase
        create :case_transition_ready_for_vetting, case: kase
        create :case_transition_vetting_in_progress, case: kase
        create :case_transition_ready_to_copy, case: kase
        kase.reload
      end
    end

    trait :ready_to_dispatch do
      transient do
        identifier { "Ready to dispatch - Offender SAR Complaint" }
      end

      after(:create) do |kase|
        create :case_transition_data_to_be_requested, case: kase
        create :case_transition_waiting_for_data, case: kase
        create :case_transition_ready_for_vetting, case: kase
        create :case_transition_vetting_in_progress, case: kase
        create :case_transition_ready_to_copy, case: kase
        create :case_transition_ready_to_dispatch, case: kase
        kase.reload
      end
    end

    trait :legal_proceedings_ongoing do
      transient do
        identifier { "Legal proceedings ongoing - Offender SAR Complaint" }
      end

      after(:create) do |kase|
        create :case_transition_data_to_be_requested, case: kase
        create :case_transition_waiting_for_data, case: kase
        create :case_transition_ready_for_vetting, case: kase
        create :case_transition_vetting_in_progress, case: kase
        create :case_transition_ready_to_copy, case: kase
        create :case_transition_ready_to_dispatch, case: kase
        create :case_transition_legal_proceedings_ongoing, case: kase
        kase.reload
      end
    end

    trait :response_required do
      transient do
        identifier { "Response required - Offender SAR Complaint" }
      end

      after(:create) do |kase|
        kase.date_responded = kase.received_date + 20.days
        create :case_transition_data_to_be_requested, case: kase
        create :case_transition_waiting_for_data, case: kase
        create :case_transition_ready_for_vetting, case: kase
        create :case_transition_vetting_in_progress, case: kase
        create :case_transition_ready_to_copy, case: kase
        create :case_transition_response_required, case: kase
        kase.reload
      end
    end

    trait :closed do
      transient do
        identifier { "Closed - Offender SAR Complaint" }
      end

      received_date  { 22.business_days.ago }
      date_responded { 4.business_days.ago }

      after(:create) do |kase|
        create :case_transition_data_to_be_requested, case: kase
        create :case_transition_waiting_for_data, case: kase
        create :case_transition_ready_for_vetting, case: kase
        create :case_transition_vetting_in_progress, case: kase
        create :case_transition_ready_to_copy, case: kase
        create :case_transition_response_required, case: kase
        create :case_transition_closed_for_offender_sar_type, case: kase
        kase.reload
      end
    end

    trait :_transition_to_accepted do
      after(:create) do |kase, evaluator|
        kase.responder_assignment.update!(user: evaluator.responder)
        kase.responder_assignment.accepted!
        create :case_transition_accept_responder_assignment,
               case: kase,
               acting_team: kase.responding_team,
               acting_user: kase.responder,
               created_at: evaluator.creation_time
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
  end

  factory :accepted_complaint_case, parent: :offender_sar_complaint do
    transient do
      identifier { "accepted case" }
    end

    after(:create) do |kase, evaluator|
      kase.assignments.create!(team: kase.responding_team, role: "responding")
      kase.responder_assignment.update!(user: evaluator.responder)
      kase.responder_assignment.accepted!
    end
  end

  factory :closed_ico_complaint, parent: :offender_sar_complaint, traits: [:closed] do
    transient do
      identifier { "closed offender sar ico-complaint case" }
    end

    complaint_type { "ico_complaint" }

    after(:create) do |kase, _|
      appeal_outcome = find_or_create(:appeal_outcome, :upheld)
      kase.appeal_outcome_id = appeal_outcome.id
      kase.save!
    end
  end

  factory :closed_litigation_complaint, parent: :offender_sar_complaint, traits: [:closed] do
    transient do
      identifier { "closed offender sar litigation-complaint case" }
    end

    complaint_type { "litigation_complaint" }

    after(:create) do |kase, _|
      kase.total_cost = Faker::Number.between(from: 0.0, to: 1_000_000.0).round(2)
      kase.settlement_cost = Faker::Number.between(from: 0.0, to: 1_000_000.0).round(2)
      kase.save!
    end
  end
end
