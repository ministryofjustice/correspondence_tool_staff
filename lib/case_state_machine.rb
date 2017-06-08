class CaseStateMachine
  include Statesman::Machine
  include Statesman::Events

  def self.event_name(event)
    if self.events.keys.include?(event.to_sym)
      event.to_s.humanize
    end
  end

  # Convenience method used by guards to get a policy object
  def self.get_policy(user_id, object)
    user = User.find(user_id)
    Pundit.policy!(user, object)
  end

  after_transition do | kase, transition|
    transition.record_state_change(kase)
  end

  state :unassigned, initial: true
  state :awaiting_responder
  state :drafting
  state :awaiting_dispatch
  state :pending_dacu_clearance
  state :responded
  state :closed

  event :assign_responder do
    guard do |object, _last_transition, options|
      CaseStateMachine.get_policy(options[:user_id], object).can_assign_case?
    end

    transition from: :unassigned, to: :awaiting_responder
  end

  event :flag_for_clearance do
    guard do |object, _last_transition, options|
      CaseStateMachine.get_policy(options[:user_id], object)
        .can_flag_for_clearance?
    end

    transition from: :unassigned,         to: :unassigned
    transition from: :awaiting_responder, to: :awaiting_responder
    transition from: :drafting,           to: :drafting
    transition from: :awaiting_dispatch,  to: :awaiting_dispatch
  end

  event :unflag_for_clearance do
    guard do |object, _last_transition, options|
      CaseStateMachine.get_policy(options[:user_id], object)
        .can_unflag_for_clearance?
    end

    transition from: :unassigned,             to: :unassigned
    transition from: :awaiting_responder,     to: :awaiting_responder
    transition from: :drafting,               to: :drafting
    transition from: :awaiting_dispatch,      to: :awaiting_dispatch
    transition from: :pending_dacu_clearance, to: :awaiting_dispatch
  end

  event :reject_responder_assignment do
    guard do |object, _last_transition, options|
      CaseStateMachine.get_policy(options[:user_id], object)
        .can_accept_or_reject_responder_assignment?
    end

    transition from: :awaiting_responder, to: :unassigned
  end

  event :accept_approver_assignment do
    guard do |object, _last_transition, options|
      CaseStateMachine.get_policy(options[:user_id], object)
        .can_accept_or_reject_approver_assignment?
    end

    transition from: :awaiting_responder,     to: :awaiting_responder
    transition from: :drafting,               to: :drafting
    transition from: :awaiting_dispatch,      to: :awaiting_dispatch
    transition from: :responded,              to: :responded
    transition from: :pending_dacu_clearance, to: :pending_dacu_clearance
  end

  event :accept_responder_assignment do
    guard do |object, _last_transition, options|
      CaseStateMachine.get_policy(options[:user_id], object)
        .can_accept_or_reject_responder_assignment?
    end

    transition from: :awaiting_responder, to: :drafting
  end

  event :add_responses do
    guard do |object, _last_transition, options|
      CaseStateMachine.get_policy(options[:user_id], object).can_add_attachment?
    end

    transition from: :drafting,          to: :awaiting_dispatch
    transition from: :awaiting_dispatch, to: :awaiting_dispatch
  end

  event :add_response_to_flagged_case do
    guard do |object, _last_transition, options|
      CaseStateMachine.get_policy(options[:user_id], object).can_add_attachment_to_flagged_case?
    end

    transition from: :drafting, to: :pending_dacu_clearance
  end

  event :add_response_to_flagged_case_and_approve do
    guard do |object, _last_transition, options|
      CaseStateMachine.get_policy(options[:user_id], object).can_add_attachment_to_flagged_case?
    end

    transition from: :pending_dacu_clearance, to: :awaiting_dispatch
  end

  event :approve do
    guard do |object, _last_transition, options|
      CaseStateMachine.get_policy(options[:user_id], object).can_approve_case?
    end

    transition from: :pending_dacu_clearance, to: :awaiting_dispatch
  end

  event :upload_response_and_approve do
    guard do |object, _last_transition, options|
      CaseStateMachine.get_policy(options[:user_id], object).can_upload_response_and_approve?
    end

    transition from: :pending_dacu_clearance, to: :awaiting_dispatch
  end


  event :reassign_approver do
    guard do |object, _last_transition, options|
      CaseStateMachine.get_policy(options[:user_id], object).can_reassign_approver?
    end

    transition from: :awaiting_responder,     to: :awaiting_responder
    transition from: :drafting,               to: :drafting
    transition from: :pending_dacu_clearance, to: :pending_dacu_clearance
  end

  event :remove_response do
    guard do |object, _last_transition, options|
      CaseStateMachine.get_policy(options[:user_id], object)
        .can_remove_attachment?
    end

    transition from: :awaiting_dispatch, to: :awaiting_dispatch
  end

  event :remove_last_response do
    guard do |object, _last_transition, options|
      CaseStateMachine.get_policy(options[:user_id], object)
        .can_remove_attachment?
    end

    transition from: :awaiting_dispatch, to: :drafting
  end

  event :respond do
    guard do |object, _last_transition, options|
      CaseStateMachine.get_policy(options[:user_id], object).can_respond?
    end

    transition from: :awaiting_dispatch, to: :responded
  end

  event :close do
    guard do |object, _last_transition, options|
      CaseStateMachine.get_policy(options[:user_id], object).can_close_case?
    end

    transition from: :responded, to: :closed
  end

  def permitted_events(user_id)
    state = current_state
    self.class.events.select do |event_name, event|
      can_trigger_event?(event_name, user_id: user_id) && event[:transitions].key?(state) && event[:transitions][state].any? do |end_state|
        can_transition_to? end_state, user_id: user_id
      end
    end.map(&:first)

    # self.class.events.select do |_, transitions|
    #   transitions.key?(state)
    # end.map(&:first)
  end

  def accept_approver_assignment!(user, approving_team)
    trigger! :accept_approver_assignment,
             approving_team_id: approving_team.id,
             user_id:           user.id,
             event:             :accept_approver_assignment
  end

  def reassign_approver!(user, original_user, approving_team)
    trigger! :reassign_approver,
             approving_team_id: approving_team.id,
             original_user_id:  original_user.id,
             user_id:           user.id,
             event:             :reassign_approver
  end

  def accept_responder_assignment!(user, responding_team)
    trigger! :accept_responder_assignment,
             responding_team_id: responding_team.id,
             user_id:            user.id,
             event:              :accept_responder_assignment
  end

  def add_responses!(user, responding_team, filenames)
    trigger! :add_responses,
             responding_team_id: responding_team.id,
             user_id:            user.id,
             filenames:          filenames,
             event:              :add_responses
  end

  def add_response_to_flagged_case!(user, responding_team, filenames)
    trigger! :add_response_to_flagged_case,
             responding_team_id: responding_team.id,
             user_id:            user.id,
             filenames:          filenames,
             event:              :add_response_to_flagged_case
  end

  def assign_responder!(user, managing_team, responding_team)
    trigger! :assign_responder,
             managing_team_id:   managing_team.id,
             responding_team_id: responding_team.id,
             user_id:            user.id,
             event:              :assign_responder
  end

  def flag_for_clearance!(user, managing_team, approving_team)
    trigger! :flag_for_clearance,
             user_id: user.id,
             managing_team_id: managing_team.id,
             approving_team_id: approving_team.id,
             event: :flag_for_clearance
  end

  def unflag_for_clearance!(user, managing_team)
    trigger! :unflag_for_clearance,
             user_id: user.id,
             managing_team_id: managing_team.id,
             event: :unflag_for_clearance
  end

  def approve!(kase, user)
    trigger! :approve,
             user_id: user.id,
             event: :approve,
             approving_team_id: kase.approving_team.id
  end

  def upload_response_and_approve!(user, approving_team, filenames)
    trigger! :upload_response_and_approve,
             user_id: user.id,
             event: :upload_response_and_approve,
             approving_team_id: approving_team.id,
             filenames: filenames
  end

  def remove_response!(user, responding_team, filename, num_attachments)
    event = num_attachments == 0 ? :remove_last_response : :remove_response
    trigger event,
            responding_team_id: responding_team.id,
            user_id: user.id,
            filenames: filename,
            event: event
  end

  def reject_responder_assignment!(responder, responding_team, message)
    trigger! :reject_responder_assignment,
             responding_team_id: responding_team.id,
             user_id:            responder.id,
             message:            message,
             event:              :reject_responder_assignment
  end

  def respond!(user, responding_team)
    trigger! :respond,
             responding_team_id: responding_team.id,
             user_id:            user.id,
             event:              :respond
  end

  def close!(user, managing_team)
    trigger! :close,
             managing_team_id: managing_team.id,
             user_id:          user.id,
             event:            :close
  end

  private

  def get_policy
    Pundit.policy!(self.object)
  end
end
