# rubocop:disable ClassLength
class Case::FOI::StandardStateMachine
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

  def configurable?
    false
  end

  after_transition do | kase, transition|
    transition.record_state_change(kase)
  end


  # The order here is important - it governs the order of the checkboxes appear on the filter by state form
  state :awaiting_responder
  state :unassigned, initial: true if initial_state.nil?
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
      if options.key?(:acting_user)
        options[:acting_user_id] = options[:acting_user].id
      end

      case_policy = Case::FOI::StandardStateMachine.get_policy options[:acting_user_id], object
      assignment = Assignment.new case: object, team_id: options[:target_team_id]
      assignment_policy = Case::FOI::StandardStateMachine.get_policy options[:acting_user_id],
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
    authorize_each_transition

    transition from: :unassigned,             to: :unassigned,          new_workflow: :standard
    transition from: :awaiting_responder,     to: :awaiting_responder,  new_workflow: :standard
    transition from: :drafting,               to: :drafting,            new_workflow: :standard
    transition from: :awaiting_dispatch,      to: :awaiting_dispatch,   new_workflow: :standard
    transition from: :pending_dacu_clearance, to: :awaiting_dispatch,   new_workflow: :standard
    transition from: :pending_dacu_clearance, to: :pending_dacu_clearance
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

    transition from: :unassigned,             to: :unassigned,              new_workflow: :standard
    transition from: :awaiting_responder,     to: :awaiting_responder,      new_workflow: :standard
    transition from: :drafting,               to: :drafting,                new_workflow: :standard
    transition from: :awaiting_dispatch,      to: :awaiting_dispatch,       new_workflow: :standard
    transition from: :pending_dacu_clearance, to: :pending_dacu_clearance,  new_workflow: :standard
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
    authorize_by_event_name

    transition from:      :unassigned,
               to:        :unassigned

    transition from:      :awaiting_responder,
               to:        :awaiting_responder

    transition from:      :drafting,
               to:        :drafting

    transition from:      :pending_dacu_clearance,
               to:        :pending_dacu_clearance

    transition from:      :pending_press_office_clearance,
               to:        :pending_press_office_clearance

    transition from:      :pending_private_office_clearance,
               to:        :pending_private_office_clearance
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

  event :extend_for_pit do
    transition from: :awaiting_dispatch,
               to:   :awaiting_dispatch
    transition from: :drafting,
               to:   :drafting
    transition from: :pending_dacu_clearance,
               to:   :pending_dacu_clearance
    transition from: :pending_press_office_clearance,
               to:   :pending_press_office_clearance
    transition from: :pending_private_office_clearance,
               to:   :pending_private_office_clearance
    transition from: :responded,
               to:   :responded
  end

  event :request_further_clearance do
    authorize :can_request_further_clearance?
    transition from: :unassigned,             to: :unassigned
    transition from: :awaiting_responder,     to: :awaiting_responder
    transition from: :drafting,               to: :drafting
    transition from: :pending_dacu_clearance, to: :pending_dacu_clearance
    transition from: :awaiting_dispatch,      to: :awaiting_dispatch
  end

  event :link_a_case do
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

  event :remove_linked_case do
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

  def accept_approver_assignment!(acting_user:, acting_team:)
    trigger! :accept_approver_assignment,
             acting_team_id:    acting_team.id,
             acting_user_id:    acting_user.id,
             event:             :accept_approver_assignment
  end

  def unaccept_approver_assignment!(acting_user:, acting_team:)
    trigger! :unaccept_approver_assignment,
             acting_team_id:    acting_team.id,
             acting_user_id:    acting_user.id,
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

  def accept_responder_assignment!(acting_user:, acting_team:)
    trigger! :accept_responder_assignment,
             acting_team_id:     acting_team.id,
             acting_user_id:     acting_user.id,
             event:              :accept_responder_assignment
  end

  def add_responses!(acting_user:, acting_team: nil, filenames:)
    team = acting_team || object.responding_team
    trigger! :add_responses,
             acting_team_id:     team.id,
             acting_user_id:     acting_user.id,
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

  def edit_case!(acting_user:, acting_team:)
    trigger! :edit_case,
             acting_team_id:    acting_team.id,
             acting_user_id:    acting_user.id,
             event:             :edit_case
  end

  def destroy_case!(acting_user:, acting_team:)
    trigger! :destroy_case,
             acting_team_id:    acting_team.id,
             acting_user_id:    acting_user.id,
             event:             :destroy_case
  end

  def assign_to_new_team!(acting_user:, acting_team:, target_team:)
    trigger! :assign_to_new_team,
             acting_team_id:    acting_team.id,
             target_team_id:    target_team.id,
             acting_user_id:    acting_user.id,
             event:             :assign_to_new_team
  end

  def flag_for_clearance!(acting_user:, acting_team:, target_team:)
    trigger! :flag_for_clearance,
             acting_user_id:    acting_user.id,
             acting_team_id:    acting_team.id,
             target_team_id:    target_team.id,
             event:             :flag_for_clearance
  end

  def unflag_for_clearance!(acting_user:, acting_team:, target_team:, message: nil)
    trigger! :unflag_for_clearance,
             acting_user_id:    acting_user.id,
             acting_team_id:    acting_team.id,
             target_team_id:    target_team.id,
             message:           message,
             event:             :unflag_for_clearance
    notify_responder(object, 'Ready to send') if ready_to_send?(object)
  end

  def take_on_for_approval!(acting_user:, acting_team:, target_team:)
    trigger! :take_on_for_approval,
             acting_user_id:    acting_user.id,
             acting_team_id:    acting_team.id,
             target_team_id:    target_team.id,
             event: :take_on_for_approval
  end

  def approve!(acting_user:, acting_team:)
    trigger! :approve,
             acting_user_id:  acting_user.id,
             event:           :approve,
             acting_team_id:  acting_team.id
    notify_responder(object, 'Ready to send') if ready_to_send?(object)
  end

  def approve_and_bypass!(acting_user:, acting_team:, message:)
    trigger! :approve_and_bypass,
             acting_user_id:    acting_user.id,
             acting_team_id:    acting_team.id,
             message:           message,
             event:             :approve_and_bypass
    notify_responder(object, 'Ready to send') if ready_to_send?(object)
  end

  def upload_response_approve_and_bypass!(user, team, filenames, message)
    trigger! :upload_response_approve_and_bypass,
             acting_user_id:    user.id,
             acting_team_id:    team.id,
             event:             :upload_response_approve_and_bypass,
             message:           message,
             filenames:         filenames
    notify_responder(object, 'Ready to send') if ready_to_send?(object)
  end

  def request_amends!(user, assignment)
    trigger! :request_amends,
             acting_user_id:  user.id,
             event:           :request_amends,
             message:         object.request_amends_comment,
             acting_team_id:  assignment.team_id
  end

  def upload_response_and_approve!(acting_user:, acting_team:, filenames:, message:)
    trigger! :upload_response_and_approve,
             acting_user_id:        acting_user.id,
             event:                 :upload_response_and_approve,
             acting_team_id:        acting_team.id,
             message:               message,
             filenames:             filenames
    notify_responder(object, 'Ready to send') if ready_to_send?(object)
  end

  def upload_response_and_return_for_redraft!(acting_user:, acting_team:, filenames:, message:)
    trigger! :upload_response_and_return_for_redraft,
             acting_user_id:        acting_user.id,
             event:                 :upload_response_and_return_for_redraft,
             acting_team_id:        acting_team.id,
             message:               message,
             filenames:             filenames
    notify_responder(object, 'Redraft requested')
  end

  def remove_response!(acting_user:, acting_team:, filenames:, num_attachments:)
    event = num_attachments == 0 ? :remove_last_response : :remove_response
    trigger event,
            acting_team_id:         acting_team.id,
            acting_user_id:         acting_user.id,
            filenames:              filenames,
            event:                  event
  end

  def reject_responder_assignment!(acting_user:, acting_team:, message:)
    trigger! :reject_responder_assignment,
             acting_team_id:      acting_team.id,
             acting_user_id:      acting_user.id,
             message:             message,
             event:               :reject_responder_assignment
  end

  def respond!(acting_user:, acting_team:)
    trigger! :respond,
             acting_team_id: acting_team.id,
             acting_user_id: acting_user.id,
             event:          :respond
  end

  def close!(acting_user:, acting_team:)
    trigger! :close,
             acting_team_id: acting_team.id,
             acting_user_id: acting_user.id,
             event:          :close
  end

  def add_message_to_case!(acting_user:, acting_team:, message:)
    trigger! :add_message_to_case,
             acting_user_id:    acting_user.id,
             acting_team_id:    acting_team.id,
             message:           message,
             event:             :add_message_to_case
    notify_responder(object, 'Message received') if able_to_send?(acting_user, object)
  end

  def extend_for_pit!(acting_user:, acting_team:, final_deadline:, message:)
    trigger! :extend_for_pit,
             acting_user_id: acting_user.id,
             acting_team_id: acting_team.id,
             final_deadline: final_deadline,
             message:        message,
             event:          :extend_for_pit
  end

  def request_further_clearance!(acting_user:, acting_team:, target_user:, target_team:)
    trigger! :request_further_clearance,
             acting_user_id:    acting_user.id,
             acting_team_id:    acting_team.id,
             target_team_id:    target_team.try(:id),
             target_user_id:    target_user.try(:id),
             event:             :request_further_clearance
  end

  def notify_kilo_case_is_ready_to_send(kase)
    NotifyResponderService.new(kase).call if kase.current_state == "awaiting_dispatch"
  end

  def link_a_case!(acting_user:, acting_team:, linked_case_id:)
    trigger! :link_a_case,
             acting_user_id: acting_user.id,
             acting_team_id: acting_team.id,
             linked_case_id: linked_case_id,
             event:          :link_a_case
  end

  def remove_linked_case!(acting_user:, acting_team:, linked_case_id:)
    trigger! :remove_linked_case,
             acting_user_id: acting_user.id,
             acting_team_id: acting_team.id,
             linked_case_id: linked_case_id,
             event:          :remove_linked_case
  end

  private

  def notify_responder(kase, mail_type)
    NotifyResponderService.new(kase, mail_type).call
  end

  def ready_to_send?(kase)
    kase.current_state == "awaiting_dispatch"
  end

  def able_to_send?(user, kase)
    message_not_sent_by_responder?(user, kase) && case_has_responder(kase)
  end

  def message_not_sent_by_responder?(user, kase)
    user != kase.responder_assignment&.user
  end

  def case_has_responder(kase)
    kase.responder_assignment&.user.present?
  end

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
