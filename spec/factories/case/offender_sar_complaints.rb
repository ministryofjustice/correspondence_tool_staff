FactoryBot.define do

  factory :offender_sar_complaint, class: Case::SAR::OffenderComplaint do
    transient do
      creation_time       { 4.business_days.ago }
      identifier          { 'New Offender SAR complaint' }
      managing_team       { find_or_create :team_branston }
      manager             { managing_team.managers.first }
      responding_team     { find_or_create :team_branston }
      responder           { responding_team.responders.first }

      approving_team      { find_or_create :team_branston }
      approver            { approving_team.approvers.first }
      i_am_deleted        { false }
    end

    current_state                   { 'to_be_assessed' }
    association :original_case, factory: [:offender_sar_case, :closed]
    sequence(:name)                 { |n| "#{identifier} name #{n}" }
    email                           { Faker::Internet.email(name: identifier) }
    sequence(:subject)              { |n| "#{identifier} subject #{n}" }
    sequence(:message)              { |n| "#{identifier} message #{n}" }
    received_date                   { Time.zone.today.to_s }
    date_of_birth                   { Time.zone.today.to_s }
    sequence(:postal_address)       { |n| "#{identifier} postal address #{n}" }
    sequence(:subject_full_name)    { |n| "Subject #{n}" }
    sequence(:subject_aliases)      { |n| "#{identifier} subject alias #{n}" }
    previous_case_numbers           { '54321' }
    prison_number                   { '123465' }
    other_subject_ids               { 'ABC 123 DEF' }
    case_reference_number           { '123 ABC 456' }
    subject_address                 { '22 Sample Address, Test Lane, Testingington, TE57ST' }
    request_dated                   { Date.parse('13-07-2010') }
    requester_reference             { '456 ABC 123' }
    subject_type                    { 'offender' }
    recipient                       { 'subject_recipient' }
    third_party                     { false }
    flag_as_high_profile            { false }
    created_at                      { creation_time }
    creator                         { responder }
    number_final_pages              { 5 }
    number_exempt_pages             { 2 }

    trait :third_party_complaint do
      third_party { true }
      third_party_relationship { 'Solicitor' }
      requester_reference { 'FOOG1234' }
      third_party_company_name { 'Foogle and Sons Solicitors at Law' }
      third_party_name { 'Mr J. Smith' }
      postal_address { '22 High Street' }
      recipient { 'requester_recipient' }
    end

    trait :to_be_assessed do
      # Default state for a new offender_sar_complaint
    end

    trait :data_review_required do
      transient do
        identifier { 'Data review required - Complaint' }
      end

      after(:create) do |kase|
        create :case_transition_data_review_required, case: kase
        kase.reload
      end
    end

    trait :data_to_be_requested do
      transient do
        identifier { 'Data to be requested - Complaint' }
      end

      after(:create) do |kase|
        create :case_transition_data_to_be_requested, case: kase
        kase.reload
      end
    end

    trait :waiting_for_data do
      transient do
        identifier { 'Waiting for data - Complaint' }
      end

      after(:create) do |kase|
        create :case_transition_data_to_be_requested, case: kase
        create :case_transition_waiting_for_data, case: kase
        kase.reload
      end
    end

    trait :ready_for_vetting do
      transient do
        identifier { 'Ready for vetting - Complaint' }
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
        identifier { 'Vetting in progress - Complaint' }
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
        identifier { 'Ready to close - Complaint' }
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

    # trait :ready_to_dispatch do
    #   date_responded { Date.today }
    #   info_held_status { find_or_create :info_status, :held }
    #   transient do
    #     identifier { 'Ready to dispatch Offender SAR' }
    #   end

    #   after(:create) do |kase|
    #     create :case_transition_waiting_for_data, case: kase
    #     create :case_transition_ready_for_vetting, case: kase
    #     create :case_transition_vetting_in_progress, case: kase
    #     create :case_transition_ready_to_copy, case: kase
    #     create :case_transition_ready_to_dispatch, case: kase
    #     kase.reload
    #   end
    # end

    trait :response_required do
      transient do
        identifier { 'Responde required - Complaint' }
      end

      received_date  { 22.business_days.ago }
      date_responded { 4.business_days.ago }

      after(:create) do |kase|
        create :case_transition_data_to_be_requested, case: kase
        create :case_transition_waiting_for_data, case: kase
        create :case_transition_ready_for_vetting, case: kase
        create :case_transition_vetting_in_progress, case: kase
        create :case_transition_ready_to_copy, case: kase
        # create :case_transition_ready_to_dispatch, case: kase
        create :case_transition_response_required, case: kase
        kase.reload
      end
    end

    trait :closed do
      transient do
        identifier { 'Closed - Complaint' }
      end

      received_date  { 22.business_days.ago }
      date_responded { 4.business_days.ago }

      after(:create) do |kase|
        create :case_transition_data_to_be_requested, case: kase
        create :case_transition_waiting_for_data, case: kase
        create :case_transition_ready_for_vetting, case: kase
        create :case_transition_vetting_in_progress, case: kase
        create :case_transition_ready_to_copy, case: kase
        # create :case_transition_ready_to_dispatch, case: kase
        create :case_transition_response_required, case: kase
        create :case_transition_closed_for_offender_sar_type, case: kase
        kase.reload
      end
    end
  end
end
