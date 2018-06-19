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
    association :case
    sort_key do
      last_sort_key =
        CaseTransition.where(case_id: case_id).order(:sort_key).last&.sort_key || 0
      last_sort_key + 10
    end
    most_recent true

    before(:create) do |transition|
      CaseTransition.where(case_id: transition.case_id).update(most_recent: false)
    end

    after(:create) do |transition|
      transition.record_state_change(transition.case)
    end
  end

  factory :flag_case_for_clearance_transition, parent: :case_transition do
    transient do
      manager        { create :manager }
      managing_team  { manager.managing_teams.first }
      approving_team { find_or_create :team_dacu_disclosure }
    end

    to_state          { self.case.current_state ||  'unassigned' }
    event             'flag_for_clearance'
    acting_user_id    { manager.id }
    acting_team_id    { managing_team.id }
    target_team_id    { approving_team.id }
  end

  factory :unflag_case_for_clearance_transition, parent: :case_transition do
    transient do
      manager        { create :manager }
      managing_team  { manager.managing_teams.first }
      approving_team { find_or_create :team_dacu_disclosure }
    end

    to_state          { self.case.current_state }
    event             'unflag_for_clearance'
    acting_user_id           { manager.id }
    acting_team_id    { managing_team.id }
    target_team_id    { approving_team.id }

  end


  factory :case_transition_assign_responder, parent: :case_transition do
    transient do
      manager         { create :manager }
      managing_team   { manager.managing_teams.first }
      responding_team { create :responding_team }
    end

    to_state           'awaiting_responder'
    event              'assign_responder'
    acting_user_id     { manager.id }
    acting_team_id     { managing_team.id }
    target_team_id     { responding_team.id }
  end

  factory :case_transition_accept_responder_assignment, parent: :case_transition do
    to_state 'drafting'
    event 'accept_responder_assignment'
  end

  factory :case_transition_reject_responder_assignment, parent: :case_transition do
    transient do
      user            { create :responder }
      responding_team { user.responding_teams.first }
    end

    to_state           'unassigned'
    event              'reject_responder_assignment'
    acting_user_id     { user.id }
    acting_team_id     { responding_team.id }
    message            { Faker::Hipster.sentence }
  end

  factory :case_transition_add_responses, parent: :case_transition do
    transient do
      responder       { create :responder }
      responding_team { responder.responding_teams.first }
    end

    to_state 'awaiting_dispatch'
    acting_user_id     { responder.id }
    acting_team_id     { responding_team.id }
    filenames          ['file1.pdf', 'file2.pdf']
    event 'add_responses'
  end

  factory :case_transition_pending_dacu_clearance, parent: :case_transition do
    transient do
      responder       { create :responder }
      responding_team { responder.responding_teams.first }
    end

    association    :case, factory: [:case, :flagged]
    to_state       'pending_dacu_clearance'
    acting_user_id { responder.id }
    acting_team_id { responding_team.id }
    filenames      ['file1.pdf', 'file2.pdf']
    event          'add_response_to_flagged_case'
  end

  factory :case_transition_approve, parent: :case_transition do
    transient do
      approver       { self.case.approvers.first }
    end

    association    :case, factory: [:case, :flagged]
    to_state       'awaiting_dispatch'
    acting_user    { approver }
    acting_team    { find_or_create :team_dacu_disclosure }
    event          'approve'
  end

  factory :case_transition_approve_for_press_office, parent: :case_transition do
    transient do
      approver       { self.case.approvers.first }
    end

    association     :case, factory: [:case, :flagged, :press_office]
    to_state        'pending_press_office_clearance'
    acting_user     { approver }
    acting_team     { find_or_create :team_press_office }
    event           'approve'
  end

  factory :case_transition_approve_for_private_office, parent: :case_transition do
    transient do
      approver       { self.case.approvers.first }
    end

    association     :case, factory: [:case, :flagged, :private_office]
    to_state       'pending_private_office_clearance'
    acting_user    { approver }
    acting_team    { find_or_create :team_private_office }
    event          'approve'
  end

  factory :case_transition_respond, parent: :case_transition do
    transient do
      responder       { create :responder }
      responding_team { responder.responding_teams.first }
    end

    to_state 'responded'
    event 'respond'
    acting_user_id      { responder.id }
    acting_team_id      { responding_team.id }
    target_user_id      { responder.id }
    target_team_id      { responding_team.id }
  end

  factory :case_transition_further_clearance, parent: :case_transition do
    transient do
      manager       { create :manager }
      managing_team { manager.managing_teams.first }
      responder     { create :responder }
      responding_team { responder.responding_teams.first }
    end

    to_state 'drafting'
    event 'request_further_clearance'
    acting_user_id      { manager.id }
    acting_team_id      { managing_team.id }

  end

  factory :case_transition_remove_response, parent: :case_transition do
    transient do
      responder       { create :responder }
      responding_team { responder.responding_teams.first }
    end

    to_state 'awaiting_dispatch'
    event 'remove_response'
    acting_user_id      { responder.id }
    acting_team_id      { responding_team.id }
    filenames           { 'file1.txt' }
  end

  factory :case_transition_close, parent: :case_transition do
    to_state 'closed'
    event 'close'
  end

  factory :case_transition_add_message_to_case, parent: :case_transition do
    event               'add_message_to_case'
    to_state            { self.case.current_state }
    message             Faker::ChuckNorris.fact
    acting_user_id      { self.case.responder.id }
    acting_team_id      { self.case.responding_team.id }
  end

  factory :case_transition_reassign_user, parent: :case_transition do
    transient do
      responder         { create :responder }
      responding_team   { responder.responding_teams.first }
      another_responder { create :responder, responding_teams: [responding_team]}
    end

    event          'reassign_user'
    to_state       { self.case.current_state }
    target_user_id { another_responder.id }
    target_team_id { responding_team.id }
    acting_user_id { responder.id }
    acting_team_id { responding_team.id }
  end

  factory :case_transition_extend_for_pit, parent: :case_transition do
    transient do
      manager        { create :manager }
      managing_team  { manager.managing_teams.first }
    end

    event          'extend_for_pit'
    to_state       { self.case.current_state }
    acting_user_id { manager.id }
    acting_team_id { managing_team.id }
  end

  factory :case_transition_request_further_clearance, parent: :case_transition do
    transient do
      manager        { create :manager }
      managing_team  { manager.managing_teams.first }
    end

    event          'request_further_clearance'
    to_state       { self.case.current_state }
    acting_user_id { manager.id }
    acting_team_id { managing_team.id }
    target_team_id { nil }
  end

  factory :case_transition_progress_for_clearance, parent: :case_transition do
    transient do
      responder        { create :responder }
      responding_team  { responder.teams.first }
      disclosure       { find_or_create :team_dacu_disclosure}
    end

    association    :case, factory: [:sar_case, :flagged]
    event          'progress_for_clearance'
    to_state       { 'pending_dacu_clearance' }
    acting_user_id { responder.id }
    acting_team_id { responding_team.id }
    target_team_id { disclosure.id }
  end
end
