FactoryBot.define do

  factory :offender_sar_case, class: Case::SAR::Offender do
    transient do
      creation_time       { 4.business_days.ago }
      identifier          { "new offender sar case" }
      managing_team       { find_or_create :team_branston }
      manager             { managing_team.managers.first }
      responding_team     { find_or_create :team_branston }
      responder           { responding_team.responders.first }

      approving_team      { find_or_create :team_branston }
      approver            { approving_team.approvers.first }
      i_am_deleted        { false }
    end

    trait :third_party do
      third_party { true }
      third_party_relationship { 'Aunt' }
    end

    current_state                   { 'data_to_be_requested' }
    sequence(:name)                 { |n| "#{identifier} name #{n}" }
    email                           { Faker::Internet.email(identifier) }
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
    subject_type                    { 'offender' }
    third_party                     { false }
    flag_as_high_profile            { false }
    created_at                      { creation_time }
    creator                         { create(:user, :orphan) }
  end

  factory :waiting_for_data_offender_sar, parent: :offender_sar_case, class: Case::SAR::Offender do
    transient do
      identifier { "waiting for data offender sar" }
    end

    created_at      { creation_time }
    received_date   { creation_time }

    after(:create) do |kase|
      create :case_transition_waiting_for_data,
             case: kase
      kase.reload
    end
  end

  factory :ready_for_vetting_offender_sar, parent: :offender_sar_case, class: Case::SAR::Offender do
    transient do
      identifier { "Ready for vetting offender sar" }
    end

    created_at      { creation_time }
    received_date   { creation_time }

    after(:create) do |kase|
      create :case_transition_ready_for_vetting,
             case: kase
      kase.reload
    end
  end

  factory :vetting_in_progress_offender_sar, parent: :offender_sar_case, class: Case::SAR::Offender do
    transient do
      identifier { "Vetting in progress offender sar" }
    end

    created_at      { creation_time }
    received_date   { creation_time }

    after(:create) do |kase|
      create :case_transition_vetting_in_progress,
             case: kase
      kase.reload
    end
  end

  factory :ready_to_copy_offender_sar, parent: :offender_sar_case, class: Case::SAR::Offender do
    transient do
      identifier { "Ready to close offender sar" }
    end

    created_at      { creation_time }
    received_date   { creation_time }

    after(:create) do |kase|
      create :case_transition_ready_to_copy,
             case: kase
      kase.reload
    end
  end

  factory :ready_to_dispatch_offender_sar, parent: :offender_sar_case, class: Case::SAR::Offender do
    transient do
      identifier { "Ready to dispatch offender sar" }
    end

    created_at      { creation_time }
    received_date   { creation_time }

    after(:create) do |kase|
      create :case_transition_ready_to_dispatch,
             case: kase
      kase.reload
    end
  end

  factory :closed_offender_sar, parent: :offender_sar_case, class: Case::SAR::Offender do
    transient do
      identifier { "Closed offender sar" }
    end

    created_at      { creation_time }
    received_date   { creation_time }

    after(:create) do |kase|
      create :case_transition_closed,
             case: kase
      kase.reload
    end
  end
end
