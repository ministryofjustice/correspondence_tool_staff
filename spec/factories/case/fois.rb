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
#  category_id          :integer
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
#  type                 :string           default("Case")
#  appeal_outcome_id    :integer
#

FactoryBot.define do

  factory :foi_case, aliases: [:case], class: Case::FOI::Standard do
    transient do
      creation_time       { 4.business_days.ago }
      identifier          { "new case" }
      managing_team       { find_or_create :team_disclosure_bmt }
      manager             { managing_team.managers.first }
      responding_team     { find_or_create :foi_responding_team }
      responder           { responding_team.responders.first }
      approving_team      { find_or_create :team_disclosure }
      approver            { approving_team.approvers.first }
      flag_for_disclosure { nil }
      flag_for_press      { false }
      flag_for_private    { false }
      press_office        { find_or_create :team_press_office }
      press_officer       { press_office.approvers.first }
      private_office      { find_or_create :team_private_office }
      private_officer     { private_office.approvers.first }
    end

    workflow                  { 'standard' }
    current_state             { 'unassigned' }
    requester_type            { 'member_of_the_public' }
    sequence(:name)           { |n| "#{identifier} name #{n}" }
    email                     { Faker::Internet.email(identifier) }
    delivery_method           { 'sent_by_email' }
    sequence(:subject)        { |n| "#{identifier} subject #{n}" }
    sequence(:message)        { |n| "#{identifier} message #{n}" }
    received_date             { Time.zone.today.to_s }
    sequence(:postal_address) { |n| "#{identifier} postal address #{n}" }
    created_at                { creation_time }

    after(:build) do |_kase, evaluator|
      evaluator.managing_team
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
               state: 'pending'
        kase.update workflow: 'trigger'

        if evaluator.flag_for_disclosure == :accepted
          disclosure_assignment = kase.assignments.for_team(
            evaluator.approving_team
          ).singular
          disclosure_assignment.update(state: 'accepted',
                                       user: evaluator.approver)
        end
      end

      if evaluator.flag_for_press
        create :case_transition_take_on_for_approval,
               case: kase,
               target_team: evaluator.press_office,
               target_user: evaluator.press_officer,
               acting_team: evaluator.press_office,
               acting_user: evaluator.press_officer
        create :approver_assignment,
               case: kase,
               team: evaluator.press_office,
               user: evaluator.press_officer,
               state: 'accepted'
      end

      if evaluator.flag_for_private
        create :case_transition_take_on_for_approval,
               case: kase,
               target_user: evaluator.private_officer,
               target_team: evaluator.private_office,
               acting_user: evaluator.press_officer,
               acting_team: evaluator.press_office
        create :approver_assignment,
               case: kase,
               team: evaluator.private_office,
               user: evaluator.private_officer,
               state: 'accepted'
      end

      if evaluator.flag_for_press || evaluator.flag_for_private
        kase.update workflow: 'full_approval'
      end

      kase.reload
    end
  end

  trait :clean do
    after(:create) do | kase |
      kase.mark_as_clean!
    end
  end

  trait :indexed do
    after(:create) do | kase |
      kase.update_index
    end
  end

  factory :case_within_escalation_deadline, parent: :case do
    creation_time { 1.business_day.ago }
    identifier { 'unassigned case within escalation deadline' }
  end

  factory :awaiting_responder_case, parent: :case,
          aliases: [:assigned_case] do
    transient do
      identifier { "assigned case" }
    end
    received_date { creation_time }

    after(:create) do |kase, evaluator|
      create :assignment,
             case: kase,
             team: evaluator.responding_team,
             state: 'pending',
             role: 'responding',
             created_at: evaluator.creation_time
      create :case_transition_assign_responder,
             case: kase,
             acting_user_id: evaluator.manager.id,
             acting_team_id: evaluator.managing_team.id,
             target_team_id: evaluator.responding_team.id,
             created_at: evaluator.creation_time

      kase.reload
    end
  end

  factory :accepted_case, parent: :assigned_case,
          aliases: [:case_being_drafted] do
    transient do
      identifier { "accepted case" }
    end

    after(:create) do |kase, evaluator|
      kase.responder_assignment.update_attribute :user, evaluator.responder
      kase.responder_assignment.accepted!
      create :case_transition_accept_responder_assignment,
             case: kase,
             acting_team: kase.responding_team,
             acting_user: kase.responder,
             created_at: evaluator.creation_time

      kase.reload
    end
  end

  factory :rejected_case, parent: :assigned_case do
    transient do
      rejection_message { Faker::Hipster.sentence }
      identifier        { "rejected case" }
    end

    after(:create) do |kase, evaluator|
      kase.responder_assignment.reasons_for_rejection =
        evaluator.rejection_message
      kase.responder_assignment.rejected!
      create :case_transition_reject_responder_assignment,
             case: kase,
             acting_user_id: evaluator.responder.id,
             acting_team_id: evaluator.responding_team.id,
             message: evaluator.rejection_message
      kase.reload
    end
  end

  factory :case_with_response, parent: :accepted_case do
    transient do
      identifier { "case with response" }
      responses { [build(:correspondence_response, type: 'response', user_id: responder.id)] }
    end

    after(:create) do |kase, evaluator|
      kase.attachments.push(*evaluator.responses)

      create :case_transition_add_responses,
             case: kase,
             acting_team: kase.responding_team,
             acting_user: kase.responder,
             filenames: [evaluator.responses.map(&:filename)]
      kase.reload
    end
  end

  factory :pending_dacu_clearance_case, parent: :accepted_case do
    transient do
      identifier          { 'case pending disclosure approval' }
      flag_for_disclosure { :accepted }
      responses           { [build(:correspondence_response,
                                   type: 'response',
                                   user_id: responder.id)] }
    end

    after(:create) do |kase, evaluator|
      kase.attachments.push(*evaluator.responses)

      create :case_transition_pending_dacu_clearance,
             case: kase,
             acting_team: evaluator.responding_team,
             acting_user: evaluator.responder,
             filenames: evaluator.responses.map(&:filename)
      kase.reload
    end
  end

  # TODO: Use traits for this instead of a separate case type
  factory :unaccepted_pending_dacu_clearance_case,
          parent: :pending_dacu_clearance_case do
    transient do
      identifier          { 'case pending disclosure approval but no accepted' }
      flag_for_disclosure { :pending }
    end
  end

  # TODO: Use traits for this instead of a separate case type
  factory :unaccepted_pending_dacu_clearance_case_flagged_for_press_and_private,
          parent: :unaccepted_pending_dacu_clearance_case do
    transient do
      flag_for_press   { true }
      flag_for_private { true }
    end
  end

  # TODO: Use traits for this instead of a separate case type
  factory :pending_dacu_clearance_case_flagged_for_press,
          parent: :pending_dacu_clearance_case do
    transient do
      flag_for_press { true }
    end
  end

  # TODO: Use traits for this instead of a separate case type
  factory :pending_dacu_clearance_case_flagged_for_press_and_private,
          parent: :pending_dacu_clearance_case_flagged_for_press do
    transient do
      flag_for_press   { true }
      flag_for_private { true }
    end
  end

  factory :pending_press_clearance_case,
          parent: :pending_dacu_clearance_case do
    transient do
      flag_for_press   { true }
      flag_for_private { true }
    end

    after(:create) do |kase, evaluator|
      create :case_transition_approve_for_press_office,
             case: kase,
             acting_user: evaluator.press_officer,
             acting_team: evaluator.press_office

      kase.reload
    end
  end

  factory :pending_private_clearance_case,
          parent: :pending_press_clearance_case do
    transient do
      flag_for_press   { true }
      flag_for_private { true }
    end

    after(:create) do |kase, evaluator|
      create :case_transition_approve_for_private_office,
             case: kase,
             acting_team: evaluator.press_office,
             acting_user: evaluator.press_officer

      kase.reload
    end
  end

  factory :redrafting_case, parent: :pending_dacu_clearance_case do
    after(:create) do |kase, evaluator|
      # team_dacu_disclosure = find_or_create :team_dacu_disclosure
      # disclosure_approval  = kase.assignments.approving.where(team_id: team_dacu_disclosure.id).first
      # disclosure_approval.update(approved: true)

      create :case_transition_upload_response_and_return_for_redraft,
             case: kase,
             acting_team: evaluator.approving_team,
             acting_user: evaluator.approver
      kase.reload
    end

  end

  factory :ready_to_send_case,
          aliases: [:approved_case],
          parent: :accepted_case do
    transient do
      identifier { "approved case requiring disclosure approval" }
      responses { [build(:correspondence_response,
                         type: 'response',
                         user_id: responder.id)] }
    end

    after(:create) do |kase, evaluator|
      kase.attachments.push(*evaluator.responses)

      unless evaluator.flag_for_disclosure == :accepted
        create :case_transition_add_responses,
               case: kase,
               acting_team: evaluator.responding_team,
               acting_user: evaluator.responder,
               filenames: evaluator.responses.map(&:filename)
      else

        create :case_transition_pending_dacu_clearance,
               case: kase,
               acting_team: evaluator.responding_team,
               acting_user: evaluator.responder,
               filenames: evaluator.responses.map(&:filename)

        final_approving_team = evaluator.approving_team
        final_approver       = evaluator.approver

        if evaluator.flag_for_press
          create :case_transition_approve_for_press_office,
                 case: kase,
                 acting_team: evaluator.approving_team,
                 acting_user: evaluator.approver

          final_approving_team = evaluator.press_office
          final_approver       = evaluator.press_officer
        end

        if evaluator.flag_for_private
          create :case_transition_approve_for_private_office,
                 case: kase,
                 acting_team: evaluator.flag_for_press ? evaluator.press_office
                                                       : evaluator.approving_team,
                 acting_user: evaluator.flag_for_press ? evaluator.press_officer
                                                       : evaluator.approver

          final_approving_team = evaluator.private_office
          final_approver       = evaluator.private_officer
        end

        create :case_transition_approve,
               case: kase,
               acting_team: final_approving_team,
               acting_user: final_approver
      end

      kase.approver_assignments.each { |a| a.update approved: true }
      kase.reload
    end
  end

  factory :responded_case, parent: :ready_to_send_case do
    transient do
      identifier { "responded case" }
    end

    date_responded { Date.today }

    after(:create) do |kase, evaluator|
      create :case_transition_respond,
             case: kase,
             acting_user: evaluator.responder,
             acting_team: evaluator.responding_team
      kase.reload
    end
  end

  factory :closed_case, parent: :responded_case do

    transient do
      identifier { "closed case" }
    end

    info_held_status { find_or_create :info_status, :held }
    outcome          { find_or_create :outcome, :granted }
    message          { 'info held, granted' }
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

    trait :old_without_info_held do
      message { 'case closed with old closure info' }

      after(:create) do |kase, _evaluator|
        kase.update_attribute :info_held_status_id, nil
        kase.update_attribute :refusal_reason, find_or_create(:refusal_reason, :exempt)
        kase.update_attribute :outcome, find_or_create(:outcome, :refused)
      end
    end

    trait :with_ncnd_exemption do
      info_held_status        { find_or_create :info_status, :ncnd }
      outcome                 { nil }
      refusal_reason          { find_or_create :refusal_reason, :ncnd }
      exemptions              { [create(:exemption, :absolute)] }
    end

    trait :late do
      received_date { 30.business_days.ago }
      date_responded { 1.business_day.ago }
    end

    trait :granted_in_full do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :granted }
      message                     { 'info held, granted' }
    end

    trait :clarification_required do
      info_held_status            { find_or_create :info_status, :ncnd }
      refusal_reason              { find_or_create :refusal_reason, :tmm }
      outcome                     { nil }
      message                     { 'info held other, clarification required' }
    end

    trait :info_not_held do
      info_held_status            { find_or_create :info_status, :not_held }
      outcome                     { nil }
      message                     { 'info not held' }
    end

    trait :other_vexatious do
      info_held_status            { find_or_create :info_status, :ncnd }
      refusal_reason              { find_or_create :refusal_reason, :vex }
      outcome                     { nil }
      message                     { 'info held other, refusal reason vexatious' }
    end

    trait :other_repeat do
      info_held_status            { find_or_create :info_status, :ncnd }
      refusal_reason              { find_or_create :refusal_reason, :repeat }
      outcome                     { nil }
      message                     { 'info held other, refusal reason - repeated request' }
    end

    trait :other_exceeded_cost do
      info_held_status            { find_or_create :info_status, :ncnd }
      refusal_reason              { find_or_create :refusal_reason, :cost }
      outcome                     { nil }
      message                     { 'info held other, refusal reason - exceeded cost' }
    end

    trait :fully_refused_exempt_s12_1 do
      info_held_status            { find_or_create :info_status, :held   }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s12_1) ] }
      message                     { 'info held, fully refused, exemption: s12' }
    end

    trait :fully_refused_exempt_s21 do
      info_held_status            { find_or_create :info_status, :held   }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s21) ] }
      message                     { 'info held, fully refused, exemption: s21' }
    end

    trait :part_refused_exempt_s21 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :part_refused }
      exemptions                  { [ find_or_create(:exemption, :s22) ] }
      message                     { 'info held, part refused, exemption: s22' }
    end

    trait :fully_refused_exempt_s22 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s22) ] }
      message                     { 'info held, fully refused, exemption: s22' }
    end

    trait :part_refused_exempt_s22a do
      info_held_status            { find_or_create :info_status, :held   }
      outcome                     { find_or_create :outcome, :part_refused }
      exemptions                  { [ find_or_create(:exemption, :s22a) ] }
      message                     { 'info held, part refused, exemption: s22a' }
    end

    trait :fully_refused_exempt_s22a do
      info_held_status            { find_or_create :info_status, :held   }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s22a) ] }
      message                     { 'info held, fully refused, exemption: s22a' }
    end

    trait :part_refused_exempt_s23 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :part_refused }
      exemptions                  { [ find_or_create(:exemption, :s23) ] }
      message                     { 'info held, part refused, exemption: s23' }
    end

    trait :fully_refused_exempt_s23 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [find_or_create(:exemption, :s23) ] }
      message                     { 'info held, fully refused, exemption: s23' }
    end

    trait :fully_refused_exempt_s24 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s24) ] }
      message                     { 'info held, fully refused, exemption: s24' }
    end

    trait :fully_refused_exempt_s26 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s26) ] }
      message                     { 'info held, fully refused, exemption: s26' }
    end

    trait :fully_refused_exempt_s27 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s27) ] }
      message                     { 'info held, fully refused, exemption: s27' }
    end

    trait :fully_refused_exempt_s28 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s28) ] }
      message                     { 'info held, fully refused, exemption: s28' }
    end

    trait :fully_refused_exempt_s29 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s29) ] }
      message                     { 'info held, fully refused, exemption: s29' }
    end

    trait :fully_refused_exempt_s30 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s30) ] }
      message                     { 'info held, fully refused, exemption: s30' }
    end

    trait :fully_refused_exempt_s31 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s31) ] }
      message                     { 'info held, fully refused, exemption: s31' }
    end

    trait :fully_refused_exempt_s32 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s32) ] }
      message                     { 'info held, fully refused, exemption: s32' }
    end

    trait :fully_refused_exempt_s33 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s33) ] }
      message                     { 'info held, fully refused, exemption: s33' }
    end

    trait :fully_refused_exempt_s34 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s34) ] }
      message                     { 'info held, fully refused, exemption: s34' }
    end

    trait :fully_refused_exempt_s35 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s35) ] }
      message                     { 'info held, fully refused, exemption: s35' }
    end

    trait :fully_refused_exempt_s36 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s36) ] }
      message                     { 'info held, fully refused, exemption: s36' }
    end

    trait :fully_refused_exempt_s37 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s37) ] }
      message                     { 'info held, fully refused, exemption: s37' }
    end

    trait :fully_refused_exempt_s38 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s38) ] }
      message                     { 'info held, fully refused, exemption: s38' }
    end

    trait :fully_refused_exempt_s40 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s40) ] }
      message                     { 'info held, fully refused, exemption: s40' }
    end

    trait :fully_refused_exempt_s41 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s41) ] }
      message                     { 'info held, fully refused, exemption: s41' }
    end

    trait :fully_refused_exempt_s42 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s42) ] }
      message                     { 'info held, fully refused, exemption: s42' }
    end

    trait :fully_refused_exempt_s33 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s33) ] }
      message                     { 'info held, fully refused, exemption: s33' }
    end

    trait :fully_refused_exempt_s43 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s43) ] }
      message                     { 'info held, fully refused, exemption: s43' }
    end

    trait :fully_refused_exempt_s44 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s44) ] }
      message                     { 'info held, fully refused, exemption: s44' }
    end
  end

  trait :flagged do
    transient do
      flag_for_disclosure { :pending }
    end
  end

  trait :pending_disclosure do
    transient do
      flag_for_disclosure { :pending }
    end
  end

  trait :flagged_accepted do
    transient do
      flag_for_disclosure { :accepted }
    end
  end

  trait :dacu_disclosure do
    # Use with :flagged or :flagged_accepted trait
    transient do
      approver { find_or_create :disclosure_specialist }
      approving_team { find_or_create :team_dacu_disclosure }
    end
  end

  trait :trigger do
    transient do
      flag_for_disclosure { :accepted }
      flag_for_press      { true }
      flag_for_private    { true }
    end
  end

  trait :full_approval do
    # Use after :flagged or :flagged_accepted trait when creating case
    transient do
      flag_for_disclosure { :accepted }
      flag_for_press      { true }
      flag_for_private    { true }
    end
  end

  trait :press_office do
    # Use after :flagged or :flagged_accepted trait when creating case
    transient do
      flag_for_press { true }
      flag_for_private { true }
    end
  end

  trait :private_office do
    transient do
      flag_for_press { true }
      flag_for_private { true }
    end
  end

  trait :accept_disclosure do
    after(:create) do |kase, evaluator|
      disclosure_assignment = kase.assignments.for_team(
        evaluator.approving_team
      ).singular
      disclosure_assignment.update(state: 'accepted')
    end
  end

  trait :sent_by_post do
    delivery_method { :sent_by_post }
    uploaded_request_files { ["#{Faker::Internet.slug}.pdf"] }
    uploading_user { create :manager }
  end

  trait :sent_by_email do
    delivery_method { :sent_by_email }
  end

  trait :with_messages do

    after(:create) do |kase|

      if kase.current_state.in?(%w( awaiting_responder ))
        Timecop.freeze(25.seconds.ago) do
          create(:case_transition_add_message_to_case,
                 case: kase,
                 acting_user: kase.responding_team.users.first,
                 acting_team: kase.responding_team,
                 message: "I'm not sure if I should accept or reject this case")
        end
      end

      if kase.current_state.in?(%w( drafting awaiting_dispatch pending_dacu_clearance responded closed ))
        Timecop.freeze(20.seconds.ago) do
          create(:case_transition_add_message_to_case,
                 case: kase,
                 acting_user: kase.responder,
                 acting_team: kase.responding_team,
                 message: "I've accepted this case as a KILO")
        end
      end

      if kase.current_state.in?(%w( awaiting_dispatch pending_dacu_clearance responded closed ))
        Timecop.freeze(15.seconds.ago) do
          create(:case_transition_add_message_to_case,
                 case: kase,
                 acting_user: kase.responder,
                 acting_team: kase.responding_team,
                 message: "I've uploaded a response")
        end
      end

      if kase.current_state.in?(%w(  pending_dacu_clearance ))
        Timecop.freeze(10.seconds.ago) do
          create(:case_transition_add_message_to_case,
                 case: kase,
                 acting_user: kase.responder,
                 acting_team: kase.responding_team,
                 message: "I'm the approver for this case")
        end
      end
    end
  end

  trait :extended_for_pit do
    after(:create) do |kase|
      create :case_transition_extend_for_pit,
             case: kase
      kase.reload
    end
  end

  trait :further_clearance_requested do
    after(:create) do |kase|
      create :case_transition_request_further_clearance,
             case: kase
      kase.reload
    end
  end
end
