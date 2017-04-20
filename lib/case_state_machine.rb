class CaseStateMachine
  include Statesman::Machine
  include Statesman::Events

  def self.event_name(event)
    if self.events.keys.include?(event.to_sym)
      event.to_s.humanize
    end
  end

  state :unassigned, initial: true
  state :awaiting_responder
  state :drafting
  state :awaiting_dispatch
  state :responded
  state :closed

  event :assign_responder do
    transition from: :unassigned, to: :awaiting_responder
  end

  event :reject_responder_assignment do
    transition from: :awaiting_responder, to: :unassigned
  end

  event :accept_responder_assignment do
    transition from: :awaiting_responder, to: :drafting
  end

  event :add_responses do
    transition from: :drafting, to: :awaiting_dispatch
    transition from: :awaiting_dispatch, to: :awaiting_dispatch
  end

  event :remove_response do
    transition from: :awaiting_dispatch, to: :awaiting_dispatch
  end

  event :remove_last_response do
    transition from: :awaiting_dispatch, to: :drafting
  end

  event :respond do
    transition from: :awaiting_dispatch, to: :responded
  end

  event :close do
    transition from: :responded, to: :closed
  end

  def accept_responder_assignment!(user, responding_team)
    trigger! :accept_responder_assignment,
             responding_team_id: responding_team.id,
             user_id:            user.id,
             event:              :accept_responder_assignment
  end

  def accept_responder_assignment(user, responding_team)
    self.accept_responder_assignment!(user, responding_team)
  rescue Statesman::TransitionFailedError, Statesman::GuardFailedError
    false
  end

  def add_responses!(user, responding_team, filenames)
    trigger! :add_responses,
             responding_team_id: responding_team.id,
             user_id:            user.id,
             filenames:          filenames,
             event:              :add_responses
  end

  def add_responses(user, responding_team, filenames)
    self.add_responses!(user, responding_team, filenames)
  rescue Statesman::TransitionFailedError, Statesman::GuardFailedError
    false
  end

  def assign_responder!(user, managing_team, responding_team)
    trigger! :assign_responder,
             managing_team_id:   managing_team.id,
             responding_team_id: responding_team.id,
             user_id:            user.id,
             event:              :assign_responder
  end

  def remove_response(user, responding_team, filename, num_attachments)
    self.remove_response!(user, responding_team, filename, num_attachments)
  rescue Statesman::TransitionFailedError, Statesman::GuardFailedError
    false
  end

  def remove_response!(user, responding_team, filename, num_attachments)
    event = num_attachments == 0 ? :remove_last_response : :remove_response
    trigger event,
            responding_team_id: responding_team.id,
            user_id: user.id,
            filenames: filename,
            event: event
  end

  def assign_responder(user, managing_team, responding_team)
    self.assign_responder!(user, managing_team, responding_team)
  rescue Statesman::TransitionFailedError, Statesman::GuardFailedError
    false
  end

  def reject_responder_assignment!(responder, responding_team, message)
    trigger! :reject_responder_assignment,
             responding_team_id: responding_team.id,
             user_id:            responder.id,
             message:            message,
             event:              :reject_responder_assignment
  end

  def reject_responder_assignment(assignee_id, message, assignment_id)
    self.reject_responder_assignment!(assignee_id, message, assignment_id)
  rescue Statesman::TransitionFailedError, Statesman::GuardFailedError
    false
  end

  def respond!(user, responding_team)
    trigger! :respond,
             responding_team_id: responding_team.id,
             user_id:            user.id,
             event:              :respond
  end

  def respond(user, responding_team)
    self.respond!(user, responding_team)
  rescue Statesman::TransitionFailedError, Statesman::GuardFailedError
    false
  end

  def close(user, managing_team)
    self.close!(user, managing_team)
  rescue Statesman::TransitionFailedError, Statesman::GuardFailedError
    false
  end

  def close!(user, managing_team)
    trigger! :close,
             managing_team_id: managing_team.id,
             user_id:          user.id,
             event:            :close
  end
end
