FactoryBot.define do

  factory :offender_sar_case, class: Case::SAR::Offender do
    transient do
      creation_time       { 4.business_days.ago }
      identifier          { 'New Offender SAR case' }
      managing_team       { find_or_create :team_branston }
      manager             { managing_team.managers.first }
      responding_team     { find_or_create :team_branston }
      responder           { responding_team.responders.first }

      approving_team      { find_or_create :team_branston }
      approver            { approving_team.approvers.first }
      i_am_deleted        { false }
    end

    current_state                   { 'data_to_be_requested' }
    sequence(:name)                 { |n| "#{identifier} name #{n}" }
    email                           { Faker::Internet.email(name: identifier) }
    reply_method                    { 'send_by_email' }
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
    subject_type                    { 'offender' }
    third_party                     { false }
    flag_as_high_profile            { false }
    created_at                      { creation_time }
    creator                         { create(:user, :orphan) }
  end

  trait :third_party do
    third_party { true }
    third_party_relationship { 'Solicitor' }
    third_party_reference { 'FOOG1234' }
    third_party_company_name { 'Foogle and Sons Solicitors at Law' }
  end

  trait :data_to_be_requested do
    # Default state for a new offender_sar_case
  end

  trait :waiting_for_data do
    transient do
      identifier { 'Waiting for data Offender SAR' }
    end

    after(:create) do |kase|
      create :case_transition_waiting_for_data, case: kase
      kase.reload
    end
  end

  trait :ready_for_vetting do
    transient do
      identifier { 'Ready for vetting Offender SAR' }
    end

    after(:create) do |kase|
      create :case_transition_waiting_for_data, case: kase
      create :case_transition_ready_for_vetting, case: kase
      kase.reload
    end
  end

  trait :vetting_in_progress do
    transient do
      identifier { 'Vetting in progress Offender SAR' }
    end

    after(:create) do |kase|
      create :case_transition_waiting_for_data, case: kase
      create :case_transition_ready_for_vetting, case: kase
      create :case_transition_vetting_in_progress, case: kase
      kase.reload
    end
  end

  trait :ready_to_copy do
    transient do
      identifier { 'Ready to close Offender SAR' }
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
    date_responded { Date.today }
    info_held_status { find_or_create :info_status, :held }
    transient do
      identifier { 'Ready to dispatch Offender SAR' }
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
      identifier { 'Closed Offender SAR' }
    end

    received_date  { 22.business_days.ago }
    date_responded { 4.business_days.ago }

    after(:create) do |kase|
      create :case_transition_waiting_for_data, case: kase
      create :case_transition_ready_for_vetting, case: kase
      create :case_transition_vetting_in_progress, case: kase
      create :case_transition_ready_to_copy, case: kase
      create :case_transition_ready_to_dispatch, case: kase
      create :case_transition_close, case: kase
      kase.reload
    end
  end
end
