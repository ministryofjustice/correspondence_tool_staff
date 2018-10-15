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
    end

    association :case
    sort_key do
      last_sort_key =
        CaseTransition.where(case_id: case_id).order(:sort_key).last&.sort_key || 0
      last_sort_key + 10
    end
    most_recent { true }

    acting_team { nil }
    acting_user { nil }
    target_team { nil }
    target_user { nil }

    # target_team_id { target_team&.id }
    # target_user_id { target_user&.id }
    # acting_team_id { acting_team&.id }
    # acting_user_id { acting_user&.id }

    before(:create) do |transition|
      CaseTransition.where(case_id: transition.case_id).update(most_recent: false)
    end

    after(:create) do |transition|
      transition.record_state_change(transition.case)
    end
  end

  factory :flag_case_for_clearance_transition, parent: :case_transition do
    transient do
    end

    to_state       { self.case.current_state ||  'unassigned' }
    event          { 'flag_for_clearance' }
    acting_team { self.case.managing_team }
    acting_user { self.case.manager }
    target_team { find_or_create :team_disclosure }
    target_user { nil }
  end

  factory :unflag_case_for_clearance_transition, parent: :case_transition do
    transient do
    end

    to_state       { self.case.current_state }
    event          { 'unflag_for_clearance' }

    acting_team { find_or_create :team_disclosure }
    acting_user { acting_team.apporvers.first }
    target_team { acting_team }
    target_user { nil }
  end

  factory :case_transition_assign_responder, parent: :case_transition do
    transient do
    end

    to_state       { 'awaiting_responder' }
    event          { 'assign_responder' }

    acting_team { self.case.managing_team }
    acting_user { self.case.manager }
    target_team { find_or_create :foi_responding_team }
    target_user { target_team.responders.first }
  end

  factory :case_transition_accept_approver_assignment, parent: :case_transition do
    transient do
    end

    event          { 'accept_approver_assignment' }
    to_state       { self.case.current_state }

    acting_team { find_or_create :team_disclosure }
    acting_user { acting_team.approvers.first }
    target_team { acting_team }
    target_user { target_team.approvers.first }
  end

  factory :case_transition_accept_responder_assignment, parent: :case_transition do
    transient do
    end

    to_state { 'drafting' }
    event    { 'accept_responder_assignment' }

    acting_team { self.case.responding_team }
    acting_user { acting_team.responders.first }
  end

  factory :case_transition_reject_responder_assignment, parent: :case_transition do
    transient do
      user            { create :responder }
      responding_team { user.responding_teams.first }
    end

    to_state       { 'unassigned' }
    event          { 'reject_responder_assignment' }
    acting_team { responding_team.id }
    acting_user { user.id }
    message        { Faker::Hipster.sentence }
  end

  factory :case_transition_take_on_for_approval, parent: :case_transition do
    transient do
    end

    event          { 'take_on_for_approval' }
    to_state       { self.case.current_state }

    acting_team { find_or_create :team_press_office }
    acting_user { acting_team&.first }
    target_team { find_or_create :team_press_office }
    target_user { target_team&.first }
  end

  factory :case_transition_add_responses, parent: :case_transition do
    transient do
    end

    to_state       { 'awaiting_dispatch' }
    filenames      { ['file1.pdf', 'file2.pdf'] }
    event          { 'add_responses' }

    acting_team { self.case.responding_team }
    acting_user { self.case.responder }
  end

  factory :case_transition_progress_for_clearance, parent: :case_transition do
    transient do
      responder         { create :responder }
      responding_team   { responder.responding_teams.first }
    end

    acting_team_id      { responding_team.id }
    acting_user_id      { responder.id }
    target_team_id      { responding_team.id }
    target_user_id      { responder.id }
    to_state            { 'pending_dacu_clearance' }
    to_workflow         { 'trigger' }
    event               { 'progress_for_clearance'}
  end

  factory :case_transition_pending_dacu_clearance, parent: :case_transition do
    transient do
    end

    association    :case, factory: [:case, :flagged]
    to_state       { 'pending_dacu_clearance' }
    event          { 'add_response_to_flagged_case' }
    filenames      { ['file1.pdf', 'file2.pdf'] }

    acting_team { self.case.responding_team }
    acting_user { self.case.responder }
  end

  factory :case_transition_approve, parent: :case_transition do
    transient do
    end

    association :case, factory: [:case, :flagged]
    to_state    { 'awaiting_dispatch' }
    event       { 'approve' }

    acting_team { find_or_create :team_disclosure }
    acting_user { acting_team.approvers.first }
  end

  factory :case_transition_approve_for_press_office, parent: :case_transition do
    transient do
    end

    association :case, factory: [:case, :flagged, :press_office]
    to_state    { 'pending_press_office_clearance' }
    event       { 'approve' }

    acting_team { find_or_create :team_disclosure }
    acting_user { acting_team.approvers.first }
  end

  factory :case_transition_approve_for_private_office, parent: :case_transition do
    transient do
    end

    association :case, factory: [:case, :flagged, :private_office]
    to_state    { 'pending_private_office_clearance' }
    event       { 'approve' }

    acting_team { find_or_create :team_press_office }
    acting_user { acting_team.approvers.first }
  end

  factory :case_transition_upload_response_and_return_for_redraft,
          parent: :case_transition do
    transient do
    end

    to_state    { 'drafting' }
    event       { 'upload_response_and_return_for_redraft' }

    acting_team { find_or_create :team_disclosure }
    acting_user { acting_team.approvers.first }
  end

  factory :case_transition_respond, parent: :case_transition do
    transient do
    end

    to_state { 'responded' }
    event { 'respond' }

    acting_team { self.case.responding_team }
    acting_user { self.case.responder }
  end

  factory :case_transition_further_clearance, parent: :case_transition do
    transient do
    end

    to_state       { 'drafting' }
    event          { 'request_further_clearance' }

    acting_team { self.case.managing_team }
    acting_user { acting_team.managers.first }
  end

  factory :case_transition_remove_response, parent: :case_transition do
    transient do
    end

    to_state  { 'awaiting_dispatch' }
    event     { 'remove_response' }
    filenames { ['file1.txt'] }

    acting_team { self.case.responding_team }
    acting_user { self.case.responder }
  end

  factory :case_transition_close, parent: :case_transition do
    transient do
    end

    to_state { 'closed' }
    event { 'close' }

    acting_team { self.case.managing_team }
    acting_user { self.case.manager }
  end

  factory :case_transition_add_message_to_case, parent: :case_transition do
    transient do
    end

    event          { 'add_message_to_case' }
    to_state       { self.case.current_state }
    message        { Faker::ChuckNorris.fact }

    acting_team { self.case.responding_team }
    acting_user { self.case.responder }
  end

  factory :case_transition_reassign_user, parent: :case_transition do
    transient do
    end

    event    { 'reassign_user' }
    to_state { self.case.current_state }

    acting_team { self.case.responding_team }
    acting_user { acting_team.first }
    target_team { self.case.responding_team }
    target_user { acting_team.last }
  end

  factory :case_transition_extend_for_pit, parent: :case_transition do
    transient do
    end

    event    { 'extend_for_pit' }
    to_state { self.case.current_state }

    acting_user { self.case.manager }
    acting_team { self.case.managing_team }
  end

  factory :case_transition_request_further_clearance, parent: :case_transition do
    transient do
    end

    event    { 'request_further_clearance' }
    to_state { self.case.current_state }

    acting_team { self.case.managing_team }
    acting_user { self.case.manager }
  end

  factory :case_transition_progress_for_clearance, parent: :case_transition do
    transient do
    end

    association :case, factory: [:sar_case, :flagged]
    event       { 'progress_for_clearance' }
    to_state    { 'pending_dacu_clearance' }

    acting_team { self.case.responding_team }
    acting_user { self.case.responder }
    target_team {
      self.case.approver_assignments.first.team }
  end

factory :case_transition_respond_to_ico, parent: :case_transition do
    transient do
    end

    association :case, factory: [:ico_foi_case]
    event       { 'respond' }
    to_state    { 'responded' }

    acting_team { find_or_create(:team_dacu_disclosure) }
    acting_user { acting_team.approvers.first }
  end

  factory :case_transition_close_ico, parent: :case_transition do
    transient do
    end

    # association         :case, factory: [:ico_foi_case]
    event               { 'close' }
    to_state            { 'closed' }

    acting_team { self.case.managing_team }
    acting_user { self.case.manager }
  end
end
