# == Schema Information
#
# Table name: case_transitions
#
#  id             :integer          not null, primary key
#  event          :string
#  to_state       :string           not null
#  metadata       :jsonb
#  sort_key       :integer          not null
#  case_id        :integer          not null
#  most_recent    :boolean          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  acting_user_id :integer
#  acting_team_id :integer
#  target_user_id :integer
#  target_team_id :integer
#  to_workflow    :string
#

FactoryBot.define do
  factory :case_transition do
    transient do
      case_responding_team_or_foi_responding_team do
        self.case.responding_team || find_or_create(:foi_responding_team)
      end

      case_responder_or_foi_responder do
        self.case.responder || find_or_create(:foi_responder)
      end
    end

    association :case, factory: :case, strategy: :create
    # association :case
    sort_key do
      last_sort_key =
        CaseTransition.where(case_id:).order(:sort_key).last&.sort_key || 0
      last_sort_key + 10
    end
    most_recent { true }

    acting_team { nil }
    acting_user { nil }
    target_team { nil }
    target_user { nil }

    before(:create) do |transition|
      CaseTransition.where(case_id: transition.case_id).update(most_recent: false)
    end

    after(:create) do |transition|
      transition.record_state_change(transition.case)
    end
  end

  factory :flag_case_for_clearance_transition, parent: :case_transition do
    to_state { self.case.current_state || "unassigned" }
    event    { "flag_for_clearance" }

    acting_team { self.case.managing_team }
    acting_user { acting_team.managers.first }
    target_team { find_or_create :team_disclosure }
    target_user { nil }
  end

  factory :unflag_case_for_clearance_transition, parent: :case_transition do
    to_state { self.case.current_state }
    event    { "unflag_for_clearance" }

    acting_team { find_or_create :team_disclosure }
    acting_user { acting_team.approvers.first }
    target_team { acting_team }
    target_user { nil }
  end

  factory :case_transition_assign_responder, parent: :case_transition do
    to_state { "awaiting_responder" }
    event    { "assign_responder" }

    acting_team { self.case.managing_team }
    acting_user { acting_team.managers.first }
    target_team { find_or_create :foi_responding_team }
    # target_user { target_team.responders.first }
  end

  factory :case_transition_assign_to_new_team, parent: :case_transition_assign_responder do
    event    { "assign_to_new_team" }
  end

  factory :case_transition_accept_approver_assignment, parent: :case_transition do
    event    { "accept_approver_assignment" }
    to_state { self.case.current_state }

    acting_team { find_or_create :team_disclosure }
    acting_user { acting_team.approvers.first }
  end

  factory :case_transition_unaccept_approver_assignment, parent: :case_transition do
    event    { "unaccept_approver_assignment" }
    to_state { self.case.current_state }

    acting_team { find_or_create :team_disclosure }
    acting_user { acting_team.approvers.first }
    target_team { acting_team }
    target_user { target_team.approvers.first }
  end

  factory :case_transition_accept_responder_assignment, parent: :case_transition do
    to_state { "drafting" }
    event    { "accept_responder_assignment" }

    acting_team { case_responding_team_or_foi_responding_team }
    acting_user { acting_team.responders.first }
  end

  factory :case_transition_reject_responder_assignment, parent: :case_transition do
    to_state { "unassigned" }
    event    { "reject_responder_assignment" }
    message  { Faker::Hipster.sentence }

    acting_team { case_responding_team_or_foi_responding_team }
    acting_user { acting_team.responders.first }
  end

  factory :case_transition_take_on_for_approval, parent: :case_transition do
    event    { "take_on_for_approval" }
    to_state { self.case.current_state }

    acting_team { find_or_create :team_press_office }
    acting_user { acting_team&.approvers&.first }
    target_team { find_or_create :team_press_office }
    target_user { target_team&.approvers&.first }
  end

  factory :case_transition_add_responses, parent: :case_transition do
    to_state  { "awaiting_dispatch" }
    filenames { ["file1.pdf", "file2.pdf"] }
    event     { "add_responses" }

    acting_team { case_responding_team_or_foi_responding_team }
    acting_user { acting_team.responders.first }
  end

  factory :case_transition_add_responses_without_state_change_for_sar, parent: :case_transition do
    to_state  { self.case.current_state }
    filenames { ["file1.pdf", "file2.pdf"] }
    event     { "add_responses" }

    acting_team { case_responding_team_or_foi_responding_team }
    acting_user { acting_team.managers.first }
  end

  factory :case_transition_progress_for_clearance, parent: :case_transition do
    association :case, factory: %i[sar_case flagged]
    event       { "progress_for_clearance" }
    to_state    { "pending_dacu_clearance" }

    acting_team { self.case.responding_team }
    acting_user { self.case.responder }
    target_team { self.case.approver_assignments.first.team }
  end

  factory :case_transition_pending_dacu_clearance, parent: :case_transition do
    association :case, factory: %i[case flagged]
    event       { "add_responses" }
    filenames   { ["file1.pdf", "file2.pdf"] }
    to_state    { "pending_dacu_clearance" }

    acting_team { case_responding_team_or_foi_responding_team }
    acting_user { acting_team.responders.first }
  end

  factory :case_transition_approve, parent: :case_transition do
    association :case, factory: %i[case flagged]
    to_state    { "awaiting_dispatch" }
    event       { "approve" }

    acting_team { find_or_create :team_disclosure }
    acting_user { acting_team.approvers.first }
  end

  factory :case_transition_approve_for_press_office, parent: :case_transition do
    association :case, factory: %i[case flagged press_office]
    to_state    { "pending_press_office_clearance" }
    event       { "approve" }

    acting_team { find_or_create :team_disclosure }
    acting_user { acting_team.approvers.first }
  end

  factory :case_transition_approve_for_private_office, parent: :case_transition do
    association :case, factory: %i[case flagged private_office]
    to_state    { "pending_private_office_clearance" }
    event       { "approve" }

    acting_team { find_or_create :team_press_office }
    acting_user { acting_team.approvers.first }
  end

  factory :case_transition_request_amends, parent: :case_transition do
    to_state    { "drafting" }
    event       { "request_amends" }

    acting_team { find_or_create :team_disclosure }
    acting_user { acting_team.approvers.first }
  end

  factory :case_transition_upload_response_and_return_for_redraft,
          parent: :case_transition do
    to_state    { "drafting" }
    event       { "upload_response_and_return_for_redraft" }

    acting_team { find_or_create :team_disclosure }
    acting_user { acting_team.approvers.first }
  end

  factory :case_transition_respond, parent: :case_transition do
    to_state { "responded" }
    event    { "respond" }

    acting_team { case_responding_team_or_foi_responding_team }
    acting_user { acting_team.responders.first }
  end

  factory :case_transition_further_clearance, parent: :case_transition do
    to_state       { "drafting" }
    event          { "request_further_clearance" }

    acting_team { self.case.managing_team }
    acting_user { acting_team.managers.first }
  end

  factory :case_transition_remove_response, parent: :case_transition do
    to_state  { "awaiting_dispatch" }
    event     { "remove_response" }
    filenames { ["file1.txt"] }

    acting_team { case_responding_team_or_foi_responding_team }
    acting_user { acting_team.users.first }
  end

  factory :case_transition_close, parent: :case_transition do
    to_state { "closed" }
    event { "close" }

    acting_team { self.case.managing_team }
    acting_user { acting_team.managers.first }
  end

  factory :case_transition_add_message_to_case, parent: :case_transition do
    event          { "add_message_to_case" }
    to_state       { self.case.current_state }
    message        { Faker::ChuckNorris.fact }

    acting_team { self.case.managing_team }
    acting_user { acting_team.managers.first }
  end

  factory :case_transition_reassign_user, parent: :case_transition do
    event    { "reassign_user" }
    to_state { self.case.current_state }

    acting_team { case_responding_team_or_foi_responding_team }
    acting_user { acting_team.users.first }
    target_team { acting_team }
    target_user { target_team.users.last }
  end

  factory :case_transition_extend_for_pit, parent: :case_transition do
    event                   { "extend_for_pit" }
    to_state                { self.case.current_state }

    acting_team             { self.case.managing_team }
    acting_user             { acting_team.managers.first }
    original_final_deadline { self.case.external_deadline }
  end

  factory :case_transition_remove_pit_extension, parent: :case_transition do
    transient do
      manager        { create :manager }
      managing_team  { manager.managing_teams.first }
    end

    event          { "remove_pit_extension" }
    to_state       { self.case.current_state }
    acting_user_id { manager.id }
    acting_team_id { managing_team.id }
  end

  factory :case_transition_request_further_clearance, parent: :case_transition do
    event    { "request_further_clearance" }
    to_state { self.case.current_state }

    acting_team { self.case.managing_team }
    acting_user { acting_team.managers.first }
  end

  factory :case_transition_respond_to_ico, parent: :case_transition do
    association :case, factory: [:ico_foi_case]
    event       { "respond" }
    to_state    { "responded" }

    acting_team { find_or_create(:team_dacu_disclosure) }
    acting_user { acting_team.approvers.first }
  end

  factory :case_transition_await_dispatch_ico, parent: :case_transition do
    association :case, factory: [:ico_foi_case]
    event       { "approve" }
    to_state    { "awaiting_dispatch" }

    acting_team { find_or_create(:team_dacu_disclosure) }
    acting_user { acting_team.approvers.first }
  end

  factory :case_transition_close_ico, parent: :case_transition do
    association         :case, factory: [:ico_foi_case]
    event               { "close" }
    to_state            { "closed" }

    acting_team { self.case.managing_team }
    acting_user { acting_team.managers.first }
  end

  factory :case_transition_extend_sar_deadline_by_30_days, parent: :case_transition do
    event                   { "extend_sar_deadline" }
    to_state                { self.case.current_state }

    acting_team             { self.case.managing_team }
    acting_user             { acting_team.managers.first }
    message                 { "Test SAR extension - 30 day" }
    final_deadline          { self.case.external_deadline + 30.days }
    original_final_deadline { self.case.external_deadline }
  end

  # Offender SAR and Offender SAR Complaint specific transitions below
  # - note use of responder and not manager
  # - single team responsible for complete case workflow
  factory :case_transition_waiting, parent: :case_transition do
    to_state { "waiting" }
    event { "mark_as_waiting" }

    acting_team { self.case.responding_team }
    acting_user { acting_team.responders.first }
  end

  factory :case_transition_data_to_be_requested, parent: :case_transition do
    to_state { "data_to_be_requested" }
    event { "mark_as_data_to_be_requested" }

    acting_team { self.case.responding_team }
    acting_user { acting_team.responders.first }
  end

  factory :case_transition_waiting_for_data, parent: :case_transition do
    to_state { "waiting_for_data" }
    event { "mark_as_waiting_for_data" }

    acting_team { self.case.responding_team }
    acting_user { acting_team.responders.first }
  end

  factory :case_transition_ready_for_vetting, parent: :case_transition do
    to_state { "ready_for_vetting" }
    event { "mark_as_ready_for_vetting" }

    acting_team { self.case.responding_team }
    acting_user { acting_team.responders.first }
  end

  factory :case_transition_vetting_in_progress, parent: :case_transition do
    to_state { "vetting_in_progress" }
    event { "mark_as_vetting_in_progress" }

    acting_team { self.case.responding_team }
    acting_user { acting_team.responders.first }
  end

  factory :case_transition_ready_to_copy, parent: :case_transition do
    to_state { "ready_to_copy" }
    event { "mark_as_ready_to_copy" }

    acting_team { self.case.responding_team }
    acting_user { acting_team.responders.first }
  end

  factory :case_transition_ready_to_dispatch, parent: :case_transition do
    to_state { "ready_to_dispatch" }
    event { "mark_as_ready_to_dispatch" }

    acting_team { self.case.responding_team }
    acting_user { acting_team.responders.first }
  end

  factory :case_transition_legal_proceedings_ongoing, parent: :case_transition do
    to_state { "legal_proceedings_ongoing" }
    event { "mark_as_legal_proceedings_ongoing" }

    acting_team { self.case.responding_team }
    acting_user { acting_team.responders.first }
  end

  factory :case_transition_closed_for_offender_sar_type, parent: :case_transition do
    to_state { "closed" }
    event { "close" }

    acting_team { self.case.responding_team }
    acting_user { acting_team.responders.first }
  end

  factory :case_transition_data_review_required, parent: :case_transition do
    to_state { "data_review_required" }
    event { "mark_as_require_data_review" }

    acting_team { self.case.responding_team }
    acting_user { acting_team.responders.first }
  end

  factory :case_transition_response_required, parent: :case_transition do
    to_state { "response_required" }
    event { "mark_as_require_response" }

    acting_team { self.case.responding_team }
    acting_user { acting_team.responders.first }
  end

  factory :case_link_foi_case, parent: :case_transition do
    association :case, factory: [:case]
    to_state  { "drafting" }
    event     { "link_a_case" }

    acting_team { self.case.responding_team }
    acting_user { acting_team.responders.first }
    linked_case_id { self.case.id }
  end

  factory :case_remove_link_foi_case, parent: :case_transition do
    association :case, factory: [:case]
    to_state  { "drafting" }
    event     { "remove_linked_case" }

    acting_team { self.case.responding_team }
    acting_user { acting_team.responders.first }
    linked_case_id { self.case.id }
  end

  factory :case_transition_require_further_action, parent: :case_transition do
    association :case, factory: [:ico_foi_case]
    event       { "require_further_action" }
    to_state    { "drafting" }

    acting_team { self.case.responding_team }
    acting_user { acting_team.responders.first }
  end

  factory :case_rejected_offender_creation, parent: :case_transition do
    to_state { "invalid_submission" }
    event    { "case/offender_sar.rejected.create" }

    acting_team { self.case.responding_team }
    acting_user { acting_team.responders.first }
  end

  factory :case_offender_creation, parent: :case_transition do
    to_state { "data_to_be_requested" }
    event    { "create" }

    acting_team { self.case.responding_team }
    acting_user { acting_team.responders.first }
  end

  factory :case_stop_the_clock, parent: :case_transition do
    event       { "stop_the_clock" }
    to_state    { "stopped" }

    acting_user { acting_team.managers.first }
    acting_team { self.case.managing_team }

    message     { "Spec Stop the Clock" }
    details do
      {
        stop_the_clock_categories: ["To clarify something - Refine everything", "Something else - Have no data"],
        stop_the_clock_reason: "Needed to stop the clock for testing",
        stop_the_clock_date: self.case.received_date + 5.days, # Arbitrary stop date
        last_status: self.case.current_state,
      }
    end
  end
end
