# rubocop:disable ClassLength
class Cases::FOIStateMachine
  include Statesman::Machine
  include Events

  def self.event_name(event)
    if self.events.keys.include?(event.to_sym)
      I18n.t("event.#{event}", default: event.to_s.humanize)
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


  # The order here is important - it governs the order of the checkboxes appear on the filter by state form
  state :awaiting_responder
  state :unassigned, initial: true
  state :drafting
  state :pending_dacu_clearance
  state :pending_press_office_clearance
  state :pending_private_office_clearance
  state :awaiting_dispatch
  state :responded
  state :closed



  event :assign_responder do
    authorize :can_assign_case?

    transition from: :unassigned, to: :awaiting_responder
  end

  event :flag_for_clearance do
    guard do |object, _last_transition, options|
      case_policy = Cases::FOIStateMachine.get_policy options[:acting_user_id], object
      assignment = Assignment.new case: object, team_id: options[:target_team_id]
      assignment_policy = Cases::FOIStateMachine.get_policy options[:acting_user_id],
                                                            assignment

      case_policy.can_flag_for_clearance? &&
        assignment_policy.can_create_for_team?
    end

    transition from: :unassigned,         to: :unassigned
    transition from: :awaiting_responder, to: :awaiting_responder
    transition from: :drafting,           to: :drafting
    transition from: :awaiting_dispatch,  to: :awaiting_dispatch
  end

  event :unflag_for_clearance do
    transition from:      :unassigned,
               to:        :unassigned,
               authorize: true
    transition from:      :awaiting_responder,
               to:        :awaiting_responder,
               authorize: true
    transition from:      :drafting,
               to:        :drafting,
               authorize: true
    transition from:      :awaiting_dispatch,
               to:        :awaiting_dispatch,
               authorize: true
    transition from:      :pending_dacu_clearance,
               to:        :awaiting_dispatch,
               authorize: true
    transition from:      :pending_dacu_clearance,
               to:        :pending_dacu_clearance,
               authorize: true
  end

  event :take_on_for_approval do
    authorize :can_take_on_for_approval?

    transition from: :unassigned,             to: :unassigned
    transition from: :awaiting_responder,     to: :awaiting_responder
    transition from: :drafting,               to: :drafting
    transition from: :awaiting_dispatch,      to: :awaiting_dispatch
    transition from: :pending_dacu_clearance, to: :pending_dacu_clearance
  end

  event :reject_responder_assignment do
    authorize :can_accept_or_reject_responder_assignment?

    transition from: :awaiting_responder, to: :unassigned
  end

  event :accept_approver_assignment do
    authorize :can_accept_or_reject_approver_assignment?

    transition from: :unassigned,             to: :unassigned
    transition from: :awaiting_responder,     to: :awaiting_responder
    transition from: :drafting,               to: :drafting
    transition from: :awaiting_dispatch,      to: :awaiting_dispatch
    transition from: :responded,              to: :responded
    transition from: :pending_dacu_clearance, to: :pending_dacu_clearance
  end

  event :unaccept_approver_assignment do
    authorize :can_unaccept_approval_assignment?

    transition from: :unassigned,             to: :unassigned
    transition from: :awaiting_responder,     to: :awaiting_responder
    transition from: :drafting,               to: :drafting
    transition from: :awaiting_dispatch,      to: :awaiting_dispatch
    transition from: :pending_dacu_clearance, to: :pending_dacu_clearance
  end

  event :accept_responder_assignment do
    authorize :can_accept_or_reject_responder_assignment?

    transition from: :awaiting_responder, to: :drafting
  end

  event :assign_to_new_team do
    transition from: :awaiting_responder,
               to: :awaiting_responder,
               authorize: true
    transition from: :drafting,
               to: :awaiting_responder,
               authorize: true
  end

  event :add_responses do
    authorize :can_add_attachment?

    transition from: :drafting,          to: :awaiting_dispatch
    transition from: :awaiting_dispatch, to: :awaiting_dispatch
  end

  event :add_response_to_flagged_case do
    transition from: :drafting, to: :pending_dacu_clearance, authorize: true
  end

  event :upload_response_and_return_for_redraft do
    transition from:      :pending_dacu_clearance,
               to:        :drafting,
               authorize: true
  end

  event :approve do
    transition from:      :pending_dacu_clearance,
               to:        :awaiting_dispatch,
               authorize: true
    transition from:      :pending_dacu_clearance,
               to:        :pending_press_office_clearance,
               authorize: true
    transition from:      :pending_press_office_clearance,
               to:        :awaiting_dispatch,
               authorize: true
    transition from:      :pending_press_office_clearance,
               to:        :pending_private_office_clearance,
               authorize: true
    transition from:      :pending_private_office_clearance,
               to:        :awaiting_dispatch,
               authorize: true
  end

  event :approve_and_bypass do
    transition from:      :pending_dacu_clearance,
               to:        :awaiting_dispatch,
               authorize: true
  end

  event :upload_response_approve_and_bypass do
    transition from:      :pending_dacu_clearance,
               to:        :awaiting_dispatch,
               authorize: true
  end

  event :request_amends do
    transition from:      :pending_press_office_clearance,
               to:        :pending_dacu_clearance,
               authorize: true
    transition from:      :pending_private_office_clearance,
               to:        :pending_dacu_clearance,
               authorize: true
  end

  event :upload_response_and_approve do
    transition from:      :pending_dacu_clearance,
               to:        :awaiting_dispatch,
               authorize: true
    transition from:      :pending_dacu_clearance,
               to:        :pending_press_office_clearance,
               authorize: true
  end

  event :edit_case do
    authorize_by_event_name
    transition from: :unassigned,                       to: :unassigned
    transition from: :awaiting_responder,               to: :awaiting_responder
    transition from: :drafting,                         to: :drafting
    transition from: :awaiting_dispatch,                to: :awaiting_dispatch
    transition from: :pending_dacu_clearance,           to: :pending_dacu_clearance
    transition from: :pending_press_office_clearance,   to: :pending_press_office_clearance
    transition from: :pending_private_office_clearance, to: :pending_private_office_clearance
    transition from: :responded,                        to: :responded
    transition from: :closed,                           to: :closed
  end

  event :destroy_case do
    authorize_by_event_name
    transition from: :unassigned,                       to: :unassigned
    transition from: :awaiting_responder,               to: :awaiting_responder
    transition from: :drafting,                         to: :drafting
    transition from: :awaiting_dispatch,                to: :awaiting_dispatch
    transition from: :pending_dacu_clearance,           to: :pending_dacu_clearance
    transition from: :pending_press_office_clearance,   to: :pending_press_office_clearance
    transition from: :pending_private_office_clearance, to: :pending_private_office_clearance
    transition from: :responded,                        to: :responded
    transition from: :closed,                           to: :closed
  end

  event :reassign_user do

    transition from:      :unassigned,
               to:        :unassigned,
               authorize: :reassign_user?

    transition from:      :awaiting_responder,
               to:        :awaiting_responder,
               authorize: :reassign_user?

    transition from:      :drafting,
               to:        :drafting,
               authorize: :reassign_user?

    transition from:      :pending_dacu_clearance,
               to:        :pending_dacu_clearance,
               authorize: :reassign_user?

    transition from:      :pending_press_office_clearance,
               to:        :pending_press_office_clearance,
               authorize: :reassign_user?

    transition from:      :pending_private_office_clearance,
               to:        :pending_private_office_clearance,
               authorize: :reassign_user?
  end

  event :remove_response do
    authorize :can_remove_attachment?

    transition from: :awaiting_dispatch, to: :awaiting_dispatch
  end

  event :remove_last_response do
    authorize :can_remove_attachment?

    transition from: :awaiting_dispatch, to: :drafting
  end

  event :respond do
    authorize :can_respond?

    transition from: :awaiting_dispatch, to: :responded
  end

  event :close do
    authorize :can_close_case?

    transition from: :responded, to: :closed
  end

  event :add_message_to_case do
    authorize :can_add_message_to_case?

    transition from: :unassigned,                       to: :unassigned
    transition from: :awaiting_responder,               to: :awaiting_responder
    transition from: :drafting,                         to: :drafting
    transition from: :awaiting_dispatch,                to: :awaiting_dispatch
    transition from: :pending_dacu_clearance,           to: :pending_dacu_clearance
    transition from: :pending_press_office_clearance,   to: :pending_press_office_clearance
    transition from: :pending_private_office_clearance, to: :pending_private_office_clearance
    transition from: :responded,                        to: :responded
  end

  def accept_approver_assignment!(user, approving_team)
    trigger! :accept_approver_assignment,
             acting_team_id:    approving_team.id,
             acting_user_id:    user.id,
             event:             :accept_approver_assignment
  end

  def unaccept_approver_assignment!(user, approving_team)
    trigger! :unaccept_approver_assignment,
             acting_team_id:    approving_team.id,
             acting_user_id:    user.id,
             event:             :unaccept_approver_assignment
  end

  def add_request_attachments!(user, managing_team, filenames)
    trigger! :add_request_attachments,
             acting_user_id:    user.id,
             acting_team_id:    managing_team.id,
             filenames:         filenames,
             event:             :add_request_attachments
  end

  def reassign_user!(target_user:, target_team:, acting_user:, acting_team:)

    trigger! :reassign_user,
             target_user_id:    target_user.id,
             target_team_id:    target_team.id,
             acting_user_id:    acting_user.id,
             acting_team_id:    acting_team.id,
             event:             :reassign_user
  end

  def create_needing_clarification!(acting_user:)
    trigger! :create_needing_clarification,
             acting_user_id:    acting_user.id,
             acting_team_id:    object.team_for_user(acting_user).id,
             event:             :create_needing_clarification
  end

  def accept_responder_assignment!(user, responding_team)
    trigger! :accept_responder_assignment,
             acting_team_id:     responding_team.id,
             acting_user_id:     user.id,
             event:              :accept_responder_assignment
  end

  def add_responses!(user, responding_team, filenames)
    trigger! :add_responses,
             acting_team_id:     responding_team.id,
             acting_user_id:     user.id,
             filenames:          filenames,
             message:            object.upload_comment,
             event:              :add_responses
  end

  def add_response_to_flagged_case!(user, responding_team, filenames)
    trigger! :add_response_to_flagged_case,
             acting_team_id:     responding_team.id,
             acting_user_id:     user.id,
             filenames:          filenames,
             message:            object.upload_comment,
             event:              :add_response_to_flagged_case
  end

  def assign_responder!(user, managing_team, responding_team)
    trigger! :assign_responder,
             acting_team_id:    managing_team.id,
             target_team_id:    responding_team.id,
             acting_user_id:    user.id,
             event:             :assign_responder
  end

  def edit_case!(user, team)
    trigger! :edit_case,
             acting_team_id:    team.id,
             acting_user_id:    user.id,
             event:             :edit_case
  end

  def destroy_case!(user, team)
    trigger! :destroy_case,
             acting_team_id:    team.id,
             acting_user_id:    user.id,
             event:             :destroy_case
  end

  def assign_to_new_team!(user, managing_team, new_team)
    trigger! :assign_to_new_team,
             acting_team_id:    managing_team.id,
             target_team_id:    new_team.id,
             acting_user_id:    user.id,
             event:             :assign_to_new_team
  end

  def flag_for_clearance!(user, managing_team, approving_team)
    trigger! :flag_for_clearance,
             acting_user_id:    user.id,
             acting_team_id:    managing_team.id,
             target_team_id:    approving_team.id,
             event:             :flag_for_clearance
  end

  def unflag_for_clearance!(user, managing_team, approving_team, message = nil)
    trigger! :unflag_for_clearance,
             acting_user_id:    user.id,
             acting_team_id:    managing_team.id,
             target_team_id:    approving_team.id,
             message:           message,
             event:             :unflag_for_clearance
    # notify_kilo_case_is_ready_to_send(object)
  end

  def take_on_for_approval!(user, managing_team, approving_team)
    trigger! :take_on_for_approval,
             acting_user_id:    user.id,
             acting_team_id:    managing_team.id,
             target_team_id:    approving_team.id,
             event: :take_on_for_approval
  end

  def approve!(user, assignment)
    trigger! :approve,
             acting_user_id:  user.id,
             event:           :approve,
             acting_team_id:  assignment.team_id
    notify_kilo_case_is_ready_to_send(object)
  end

  def approve_and_bypass!(user, assignment, message)
    trigger! :approve_and_bypass,
             acting_user_id:    user.id,
             acting_team_id:    assignment.team_id,
             message:           message,
             event:             :approve_and_bypass
    notify_kilo_case_is_ready_to_send(object)
  end

  def upload_response_approve_and_bypass!(user, team, filenames, message)
    trigger! :upload_response_approve_and_bypass,
             acting_user_id:    user.id,
             acting_team_id:    team.id,
             event:             :upload_response_approve_and_bypass,
             message:           message,
             filenames:         filenames
    notify_kilo_case_is_ready_to_send(object)
  end

  def request_amends!(user, assignment)
    trigger! :request_amends,
             acting_user_id:  user.id,
             event:           :request_amends,
             message:         object.request_amends_comment,
             acting_team_id:  assignment.team_id
  end

  def upload_response_and_approve!(user, approving_team, filenames)
    trigger! :upload_response_and_approve,
             acting_user_id:        user.id,
             event:                 :upload_response_and_approve,
             acting_team_id:        approving_team.id,
             message:               object.upload_comment,
             filenames:             filenames
    notify_kilo_case_is_ready_to_send(object)
  end

  def upload_response_and_return_for_redraft!(user, approving_team, filenames)
    trigger! :upload_response_and_return_for_redraft,
             acting_user_id:        user.id,
             event:                 :upload_response_and_return_for_redraft,
             acting_team_id:        approving_team.id,
             message:               object.upload_comment,
             filenames:             filenames
  end

  def remove_response!(user, responding_team, filename, num_attachments)
    event = num_attachments == 0 ? :remove_last_response : :remove_response
    trigger event,
            acting_team_id:         responding_team.id,
            acting_user_id:         user.id,
            filenames:              filename,
            event:                  event
  end

  def reject_responder_assignment!(responder, responding_team, message)
    trigger! :reject_responder_assignment,
             acting_team_id:      responding_team.id,
             acting_user_id:      responder.id,
             message:             message,
             event:               :reject_responder_assignment
  end

  def respond!(user, responding_team)
    trigger! :respond,
             acting_team_id:        responding_team.id,
             acting_user_id:        user.id,
             event:                 :respond
  end

  def close!(user, managing_team)
    trigger! :close,
             acting_team_id: managing_team.id,
             acting_user_id:   user.id,
             event:            :close
  end

  def add_message_to_case!(user, team, message)
    trigger! :add_message_to_case,
             acting_user_id:    user.id,
             acting_team_id:    team.id,
             message:           message,
             event:             :add_message_to_case
  end

  def notify_kilo_case_is_ready_to_send(kase)
    NotifyResponderService.new(kase).call if kase.approver_assignments.any?
  end

  private

  def get_policy
    Pundit.policy!(self.object)
  end

  def approve_or_escalate_case_for_team(team, next_event)
    if team.in? object.approving_teams
      next_event
    else
      :approve
    end
  end


end
# rubocop:enable ClassLength
