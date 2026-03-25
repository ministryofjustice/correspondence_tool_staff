# == Schema Information
#
# Table name: cases
#
#  id                   :integer          not null, primary key
#  name                 :string
#  email                :string
#  message              :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  received_date        :date
#  postal_address       :string
#  subject              :string
#  properties           :jsonb
#  requester_type       :enum
#  number               :string           not null
#  date_responded       :date
#  outcome_id           :integer
#  refusal_reason_id    :integer
#  current_state        :string
#  last_transitioned_at :datetime
#  delivery_method      :enum
#  workflow             :string
#  deleted              :boolean          default(FALSE)
#  info_held_status_id  :integer
#  type                 :string
#  appeal_outcome_id    :integer
#  dirty                :boolean          default(FALSE)
#

FactoryBot.define do
  factory :sar_case, class: "Case::SAR::Standard" do
    transient do
      creation_time       { 4.business_days.ago }
      identifier          { "new sar case" }
      managing_team       { find_or_create :team_dacu }
      manager             { managing_team.managers.first }
      responding_team     { find_or_create :sar_responding_team }
      responder           { responding_team.responders.first }
      flag_for_disclosure { nil }
      approving_team      { find_or_create :team_disclosure }
      approver            { approving_team.approvers.first }
      i_am_deleted        { false }
    end

    current_state                 { "unassigned" }
    sequence(:name)               { |n| "#{identifier} name #{n}" }
    email                         { Faker::Internet.email(name: identifier) }
    reply_method                  { "send_by_email" }
    sequence(:subject)            { |n| "#{identifier} subject #{n}" }
    sequence(:message)            { |n| "#{identifier} message #{n}" }
    received_date                 { Time.zone.today.to_s }
    sequence(:postal_address)     { |n| "#{identifier} postal address #{n}" }
    sequence(:subject_full_name)  { |n| "Subject #{n}" }
    subject_type                  { "offender" }
    request_method                { "post" }
    third_party                   { false }
    created_at                    { creation_time }
    creator                       { create(:user, :orphan) }

    trait :third_party do
      third_party { true }
      third_party_relationship { "Aunt" }
    end

    trait :deleted_case do
      i_am_deleted { true }
    end

    after(:create) do |kase, evaluator|
      ma = kase.managing_assignment
      ma.update! created_at: evaluator.creation_time

      if evaluator.flag_for_disclosure
        create :flag_case_for_clearance_transition,
               case: kase,
               acting_team: evaluator.managing_team,
               acting_user: evaluator.managing_team.managers.first,
               target_team: evaluator.approving_team
        create :approver_assignment,
               case: kase,
               team: evaluator.approving_team,
               state: "pending"
        kase.update! workflow: "trigger"

        if evaluator.flag_for_disclosure == :accepted
          disclosure_assignment = kase.assignments.for_team(
            evaluator.approving_team,
          ).singular
          disclosure_assignment.update!(state: "accepted",
                                        user: evaluator.approver)
        end
      end

      if evaluator.i_am_deleted
        kase.update! deleted: true, reason_for_deletion: "Needs to go"
      end
    end

    trait :flagged do
      transient do
        flag_for_disclosure { :pending }
      end
    end

    trait :flagged_accepted do
      transient do
        flag_for_disclosure { :accepted }
      end
    end

    trait :extended_deadline_sar do
      after(:create) do |kase, evaluator|
        create :case_transition_extend_sar_deadline_by_30_days,
               case: kase,
               acting_team: evaluator.managing_team,
               acting_user: evaluator.manager

        kase.extend_deadline!(kase.external_deadline + 30.days, 1)
      end
    end

    trait :stopped do
      after(:create) do |kase, evaluator|
        create :case_transition_stop_the_clock, case: kase, acting_user: evaluator.manager
      end
    end
  end

  factory :awaiting_responder_sar, parent: :sar_case, aliases: [:assigned_sar], class: "Case::SAR::Standard" do
    transient do
      identifier { "assigned sar" }
    end

    created_at      { creation_time }
    received_date   { creation_time }

    after(:create) do |kase, evaluator|
      create :assignment,
             case: kase,
             team: evaluator.responding_team,
             state: "pending",
             role: "responding",
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

  factory :accepted_sar, parent: :assigned_sar,
                         aliases: [:sar_being_drafted] do
    transient do
      identifier { "accepted sar" }
    end

    after(:create) do |kase, evaluator|
      responder = evaluator.responder || responding_team.responders.first
      kase.responder_assignment.update!(user: responder)
      kase.responder_assignment.accepted!
      create :case_transition_accept_responder_assignment,
             case: kase,
             acting_user: kase.responder,
             acting_team: kase.responding_team,
             created_at: evaluator.creation_time
      kase.reload
    end
  end

  factory :pending_dacu_clearance_sar, parent: :accepted_sar do
    transient do
      flag_for_disclosure { :accepted }
    end

    after(:create) do |kase, evaluator|
      create :case_transition_progress_for_clearance,
             case: kase,
             acting_team: evaluator.responding_team,
             acting_user: evaluator.responder,
             target_team: evaluator.approving_team
      kase.reload
    end
  end

  factory :approved_sar, parent: :pending_dacu_clearance_sar do
    transient do
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

  factory :amends_requested_sar, parent: :pending_dacu_clearance_sar do
    transient do
      is_draft_compliant? { true }
    end

    after(:create) do |kase, evaluator|
      transition = create :case_transition_request_amends,
                          case: kase,
                          acting_team: evaluator.approving_team,
                          acting_user: evaluator.approver
      if evaluator.is_draft_compliant?
        kase.update!(date_draft_compliant: transition.created_at)
      end
      kase.approver_assignments.each { |a| a.update approved: true }
      kase.reload
    end
  end

  factory :closed_sar, parent: :accepted_sar do
    missing_info { false }

    transient do
      identifier { "closed sar" }
    end

    received_date  { 22.business_days.ago }
    date_responded { 4.business_days.ago }

    after(:create) do |kase, evaluator|
      if evaluator.flag_for_disclosure
        create :case_transition_progress_for_clearance,
               case: kase,
               acting_team: evaluator.responding_team,
               acting_user: evaluator.responder,
               target_team: evaluator.approving_team

        create :case_transition_approve,
               case: kase,
               acting_team: evaluator.approving_team,
               acting_user: evaluator.approver
      end

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
    end
  end

  factory :closed_sar_with_response, parent: :closed_sar do
    transient do
      identifier { "closed sar case with response" }
      responses { [build(:correspondence_response, type: "response", user_id: responder.id)] }
    end

    after(:create) do |kase, evaluator|
      kase.attachments.push(*evaluator.responses)

      create :case_transition_add_responses_without_state_change_for_sar,
             case: kase,
             acting_team: kase.managing_team,
             acting_user: kase.manager,
             filenames: [evaluator.responses.map(&:filename)]
      kase.reload
    end
  end

  trait :clarification_required do
    refusal_reason              { find_or_create :refusal_reason, :sar_tmm }
    missing_info                { true }
    message                     { "info held other, clarification required" }
  end
end
