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

FactoryGirl.define do

  factory :foi_case, aliases: [:case], class: Case::FOI::Standard do
    transient do
      creation_time { 4.business_days.ago }
      identifier "new case"
      managing_team { find_or_create :team_dacu }
    end

    current_state 'unassigned'
    requester_type 'member_of_the_public'
    sequence(:name) { |n| "#{identifier} name #{n}" }
    email { Faker::Internet.email(identifier) }
    delivery_method 'sent_by_email'
    sequence(:subject) { |n| "#{identifier} subject #{n}" }
    sequence(:message) { |n| "#{identifier} message #{n}" }
    received_date { Time.zone.today.to_s }
    sequence(:postal_address) { |n| "#{identifier} postal address #{n}" }
    created_at { creation_time }

    after(:build) do |_kase, evaluator|
      evaluator.managing_team
    end

    after(:create) do | kase, evaluator|
      ma = kase.managing_assignment
      ma.update! created_at: evaluator.creation_time
    end
  end

  factory :case_within_escalation_deadline, parent: :case do
    creation_time { 1.business_day.ago }
    identifier 'unassigned case within escalation deadline'
  end

  factory :awaiting_responder_case, parent: :case,
          aliases: [:assigned_case] do
    transient do
      identifier "assigned case"
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

  factory :accepted_case, parent: :assigned_case,
          aliases: [:case_being_drafted] do
    transient do
      identifier "accepted case"
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

  factory :rejected_case, parent: :assigned_case do
    transient do
      rejection_message { Faker::Hipster.sentence }
      responder         { create :responder }
      responding_team   { responder.responding_teams.first }
      identifier        "rejected case"
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
      identifier "case with response"
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

  factory :pending_dacu_clearance_case, parent: :case_with_response do
    transient do
      approving_team { find_or_create :team_dacu_disclosure }
      approver       { create :disclosure_specialist }
    end
    workflow 'trigger'

    after(:create) do |kase, evaluator|
      create :approver_assignment,
             case: kase,
             team: evaluator.approving_team,
             state: 'accepted',
             user_id: evaluator.approver.id

      create :case_transition_pending_dacu_clearance,
             case_id: kase.id,
             acting_user_id: evaluator.responder.id
      kase.reload
    end
  end

  factory :unaccepted_pending_dacu_clearance_case, parent: :case_with_response do
    transient do
      approving_team { find_or_create :team_dacu_disclosure }
    end

    workflow 'trigger'

    after(:create) do |kase, evaluator|
      create :approver_assignment,
             case: kase,
             team: evaluator.approving_team,
             state: 'pending',
             user_id: nil

      create :case_transition_pending_dacu_clearance,
             case_id: kase.id,
             acting_user_id: evaluator.responder.id
      kase.reload
    end
  end

  factory :pending_dacu_clearance_case_flagged_for_press, parent: :pending_dacu_clearance_case do
    transient do
      press_office  { find_or_create :team_press_office }
      press_officer { find_or_create :press_officer }
    end
    after(:create) do |kase, evaluator|
      create :approver_assignment,
             case: kase,
             team: evaluator.press_office,
             state: 'accepted',
             user: evaluator.press_officer
      kase.reload
      kase.update(workflow: 'full_approval')
    end
  end

  factory :pending_dacu_clearance_case_flagged_for_press_unaccepted_by_press, parent: :pending_dacu_clearance_case do
    transient do
      press_office  { find_or_create :team_press_office }
      press_officer { find_or_create :press_officer }
    end
    after(:create) do |kase, evaluator|
      create :approver_assignment,
             case: kase,
             team: evaluator.press_office,
             state: 'pending'
      kase.reload
      kase.update(workflow: 'full_approval')
    end
  end

  factory :pending_dacu_clearance_case_flagged_for_press_and_private, parent: :pending_dacu_clearance_case_flagged_for_press do
    transient do
      private_office  { find_or_create :team_private_office }
      private_officer { find_or_create :private_officer }
    end
    after(:create) do |kase, evaluator|
      create :approver_assignment,
             case: kase,
             team: evaluator.private_office,
             state: 'accepted',
             user: evaluator.private_officer
      kase.reload
      kase.update(workflow: 'full_approval')
    end
  end

  factory :pending_dacu_clearance_case_flagged_for_press_and_private_unaccepted, parent: :pending_dacu_clearance_case_flagged_for_press_unaccepted_by_press do
    transient do
      private_office  { find_or_create :team_private_office }
      private_officer { find_or_create :private_officer }
    end
    after(:create) do |kase, evaluator|
      create :approver_assignment,
             case: kase,
             team: evaluator.private_office,
             state: 'pending'
      kase.reload
      kase.update(workflow: 'full_approval')
    end
  end

  factory :pending_press_clearance_case, parent: :pending_dacu_clearance_case do
    transient do
      press_office   { find_or_create :team_press_office }
      press_officer  { find_or_create :press_officer }
    end

    after(:create) do |kase, evaluator|

      kase.approver_assignments.for_team(evaluator.approving_team)
          .first.update!(approved: true)

      create :approver_assignment,
             case: kase,
             team: evaluator.press_office,
             state: 'accepted',
             user: evaluator.press_officer

      create :case_transition_approve_for_press_office,
             case: kase,
             acting_user_id: evaluator.approver.id
      kase.reload
      kase.update(workflow: 'full_approval')
    end
  end

  factory :pending_private_clearance_case, parent: :pending_dacu_clearance_case do
    transient do
      press_office    { find_or_create :team_press_office }
      press_officer   { find_or_create :press_officer }
      private_office  { find_or_create :team_private_office }
      private_officer { find_or_create :private_officer }
    end

    after(:create) do |kase, evaluator|

      kase.approver_assignments.for_team(evaluator.approving_team)
          .first.update!(approved: true)

      create :approver_assignment,
             case: kase,
             team: evaluator.press_office,
             state: 'accepted',
             user: evaluator.press_officer

      create :approver_assignment,
             case: kase,
             team: evaluator.private_office,
             state: 'accepted',
             user: evaluator.private_officer

      create :case_transition_approve_for_press_office,
             case: kase,
             target_user_id: evaluator.approver.id
      create :case_transition_approve_for_private_office,
             case: kase,
             target_user_id: evaluator.approver.id

      kase.reload
      kase.update(workflow: 'full_approval')

    end
  end

  factory :approved_case, parent: :pending_dacu_clearance_case do
    transient do
      approving_team { find_or_create :team_dacu_disclosure }
      approver { create :disclosure_specialist }
    end

    after(:create) do |kase, evaluator|
      create :case_transition_approve,
             case: kase,
             acting_team_id: evaluator.approving_team.id,
             acting_user_id: evaluator.approver.id

      kase.approver_assignments.each { |a| a.update approved: true }
      kase.reload
    end
  end

  factory :responded_case, parent: :case_with_response do
    transient do
      identifier "responded case"
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

  factory :closed_case, parent: :responded_case do

    info_held_status            { find_or_create :info_status, :held }
    outcome                     { find_or_create :outcome, :granted }
    message                     'info held, granted'

    transient do
      identifier "closed case"
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


    trait :with_ncnd_exemption do
      info_held_status        { find_or_create :info_status, :ncnd }
      outcome                 nil
      refusal_reason          { find_or_create :refusal_reason, :ncnd }
      exemptions              { [create(:exemption, :absolute)] }
    end

    trait :late do
      received_date 30.business_days.ago
      date_responded 1.business_day.ago
    end

    trait :granted_in_full do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :granted }
      message                     'info held, granted'
    end

    trait :clarification_required do
      info_held_status            { find_or_create :info_status, :ncnd }
      refusal_reason              { find_or_create :refusal_reason, :tmm }
      outcome                     nil
      message                     'info held other, clarification required'
    end

    trait :info_not_held do
      info_held_status            { find_or_create :info_status, :not_held }
      outcome                     nil
      message                     'info not held'
    end

    trait :other_vexatious do
      info_held_status            { find_or_create :info_status, :ncnd }
      refusal_reason              { find_or_create :refusal_reason, :vex }
      outcome                     nil
      message                     'info held other, refusal reason vexatious'
    end

    trait :other_repeat do
      info_held_status            { find_or_create :info_status, :ncnd }
      refusal_reason              { find_or_create :refusal_reason, :repeat }
      outcome                     nil
      message                     'info held other, refusal reason - repeated request'
    end

    trait :other_exceeded_cost do
      info_held_status            { find_or_create :info_status, :ncnd }
      refusal_reason              { find_or_create :refusal_reason, :cost }
      outcome                     nil
      message                     'info held other, refusal reason - exceeded cost'
    end

    trait :fully_refused_exempt_s12_1 do
      info_held_status            { find_or_create :info_status, :held   }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s12_1) ] }
      message                     'info held, fully refused, exemption: s12'
    end

    trait :fully_refused_exempt_s21 do
      info_held_status            { find_or_create :info_status, :held   }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s21) ] }
      message                     'info held, fully refused, exemption: s21'
    end

    trait :part_refused_exempt_s21 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :part_refused }
      exemptions                  { [ find_or_create(:exemption, :s22) ] }
      message                     'info held, part refused, exemption: s22'
    end

    trait :fully_refused_exempt_s22 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s22) ] }
      message                     'info held, fully refused, exemption: s22'
    end

    trait :part_refused_exempt_s22a do
      info_held_status            { find_or_create :info_status, :held   }
      outcome                     { find_or_create :outcome, :part_refused }
      exemptions                  { [ find_or_create(:exemption, :s22a) ] }
      message                     'info held, part refused, exemption: s22a'
    end

    trait :fully_refused_exempt_s22a do
      info_held_status            { find_or_create :info_status, :held   }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s22a) ] }
      message                     'info held, fully refused, exemption: s22a'
    end

    trait :part_refused_exempt_s23 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :part_refused }
      exemptions                  { [ find_or_create(:exemption, :s23) ] }
      message                     'info held, part refused, exemption: s23'
    end

    trait :fully_refused_exempt_s23 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [find_or_create(:exemption, :s23) ] }
      message                     'info held, fully refused, exemption: s23'
    end

    trait :fully_refused_exempt_s24 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s24) ] }
      message                     'info held, fully refused, exemption: s24'
    end

    trait :fully_refused_exempt_s26 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s26) ] }
      message                     'info held, fully refused, exemption: s26'
    end

    trait :fully_refused_exempt_s27 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s27) ] }
      message                     'info held, fully refused, exemption: s27'
    end

    trait :fully_refused_exempt_s28 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s28) ] }
      message                     'info held, fully refused, exemption: s28'
    end

    trait :fully_refused_exempt_s29 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s29) ] }
      message                     'info held, fully refused, exemption: s29'
    end

    trait :fully_refused_exempt_s30 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s30) ] }
      message                     'info held, fully refused, exemption: s30'
    end

    trait :fully_refused_exempt_s31 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s31) ] }
      message                     'info held, fully refused, exemption: s31'
    end

    trait :fully_refused_exempt_s32 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s32) ] }
      message                     'info held, fully refused, exemption: s32'
    end

    trait :fully_refused_exempt_s33 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s33) ] }
      message                     'info held, fully refused, exemption: s33'
    end

    trait :fully_refused_exempt_s34 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s34) ] }
      message                     'info held, fully refused, exemption: s34'
    end

    trait :fully_refused_exempt_s35 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s35) ] }
      message                     'info held, fully refused, exemption: s35'
    end

    trait :fully_refused_exempt_s36 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s36) ] }
      message                     'info held, fully refused, exemption: s36'
    end

    trait :fully_refused_exempt_s37 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s37) ] }
      message                     'info held, fully refused, exemption: s37'
    end

    trait :fully_refused_exempt_s38 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s38) ] }
      message                     'info held, fully refused, exemption: s38'
    end

    trait :fully_refused_exempt_s40 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s40) ] }
      message                     'info held, fully refused, exemption: s40'
    end

    trait :fully_refused_exempt_s41 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s41) ] }
      message                     'info held, fully refused, exemption: s41'
    end

    trait :fully_refused_exempt_s42 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s42) ] }
      message                     'info held, fully refused, exemption: s42'
    end

    trait :fully_refused_exempt_s33 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s33) ] }
      message                     'info held, fully refused, exemption: s33'
    end

    trait :fully_refused_exempt_s43 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s43) ] }
      message                     'info held, fully refused, exemption: s43'
    end

    trait :fully_refused_exempt_s44 do
      info_held_status            { find_or_create :info_status, :held }
      outcome                     { find_or_create :outcome, :refused }
      exemptions                  { [ find_or_create(:exemption, :s44) ] }
      message                     'info held, fully refused, exemption: s44'
    end
  end

  trait :flagged do
    transient do
      approving_team { find_or_create :approving_team }
      disclosure_assignment_state { 'pending' }
    end


    after(:create) do |kase, evaluator|
      create :approver_assignment,
             case: kase,
             team: evaluator.approving_team,
             state: 'pending'
      create :flag_case_for_clearance_transition,
             case: kase,
             acting_team_id: evaluator.approving_team.id
      kase.update(workflow: 'trigger')
      kase.reload
    end
  end

  trait :flagged_accepted do
    transient do
      approver { create :approver }
      approving_team { approver.approving_team }
      disclosure_assignment_state { 'accepted' }
    end


    after(:create) do |kase, evaluator|
      create :approver_assignment,
             case: kase,
             user: evaluator.approver,
             team: evaluator.approving_team,
             state: 'accepted'
      create :flag_case_for_clearance_transition,
             case: kase,
             target_team_id: evaluator.approving_team.id
      kase.update(workflow: 'trigger')
    end
  end

  trait :dacu_disclosure do
    # Use with :flagged or :flagged_accepted trait
    transient do
      approver { create :disclosure_specialist }
      approving_team { find_or_create :team_dacu_disclosure }
    end
  end

  trait :press_office do
    # Use after :flagged or :flagged_accepted trait when creating case
    transient do
      approver                    { create :press_officer }
      approving_team              { find_or_create :team_press_office }
      disclosure_specialist       { create :disclosure_specialist }
      disclosure_team             { find_or_create :team_dacu_disclosure }
      private_officer             { create :private_officer }
      private_office              { find_or_create :team_private_office }
    end

    after(:create) do |kase, evaluator|
      disclosure_specialist = if evaluator.disclosure_assignment_state == 'accepted'
                                evaluator.disclosure_specialist
                              else
                                nil
                              end
      create :approver_assignment,
             case: kase,
             team: evaluator.disclosure_team,
             user: disclosure_specialist,
             state: evaluator.disclosure_assignment_state

      create :approver_assignment,
             case: kase,
             team: evaluator.private_office,
             user: evaluator.private_officer,
             state: evaluator.disclosure_assignment_state

      kase.update(workflow: 'full_approval')
    end
  end

  trait :private_office do
    # Use after :flagged or :flagged_accepted trait when creating case
    transient do
      approver                    { create :private_officer }
      approving_team              { find_or_create :team_private_office }
      disclosure_team             { find_or_create :team_dacu_disclosure }
      disclosure_assignment_state { 'pending' }
    end

    after(:create) do |kase, evaluator|
      create :approver_assignment,
             case: kase,
             team: evaluator.disclosure_team,
             state: evaluator.disclosure_assignment_state
      kase.update(workflow: 'full_approval')
    end
  end

  trait :sent_by_post do
    delivery_method :sent_by_post
    uploaded_request_files { ["#{Faker::Internet.slug}.pdf"] }
    uploading_user { create :manager }
  end

  trait :sent_by_email do
    delivery_method :sent_by_email
  end

  trait :with_messages do

    after(:create) do |kase|

      if kase.current_state.in?(%w( awaiting_responder ))
        Timecop.freeze(25.seconds.ago) do
          create(:case_transition_add_message_to_case,
                 case_id: kase.id,
                 acting_user_id: kase.responding_team.users.first.id,
                 acting_team_id: kase.responding_team.id,
                 message: "I'm not sure if I should accept or reject this case")
        end
      end

      if kase.current_state.in?(%w( drafting awaiting_dispatch pending_dacu_clearance responded closed ))
        Timecop.freeze(20.seconds.ago) do
          create(:case_transition_add_message_to_case,
                 case_id: kase.id,
                 acting_user_id: kase.responder.id,
                 acting_team_id: kase.responding_team.id,
                 message: "I've accepted this case as a KILO")
        end
      end

      if kase.current_state.in?(%w( awaiting_dispatch pending_dacu_clearance responded closed ))
        Timecop.freeze(15.seconds.ago) do
          create(:case_transition_add_message_to_case,
                 case_id: kase.id,
                 acting_user_id: kase.responder.id,
                 acting_team_id: kase.responding_team.id,
                 message: "I've uploaded a response")
        end
      end

      if kase.current_state.in?(%w(  pending_dacu_clearance ))
        Timecop.freeze(10.seconds.ago) do
          create(:case_transition_add_message_to_case,
                 case_id: kase.id,
                 acting_user_id: kase.responder.id,
                 acting_team_id: kase.responding_team.id,
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
