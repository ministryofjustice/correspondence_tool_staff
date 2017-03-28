class CaseStateMachine
  include Statesman::Machine
  include Statesman::Events

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

  def add_responses!(assignee_id, filenames)
    trigger! :add_responses,
             assignee_id: assignee_id,
             user_id:     assignee_id,
             filenames:   filenames,
             event:       :add_responses
  end

  def remove_response(assignee_id, filename, num_responses)
    self.remove_response!(assignee_id, filename, num_responses)
  rescue Statesman::TransitionFailedError, Statesman::GuardFailedError
    false
  end

  def remove_response!(assignee_id, filename, num_attachments)
    event = num_attachments == 0 ? :remove_last_response : :remove_response
    trigger event,
            assignee_id: assignee_id,
            user_id: assignee_id,
            filenames: filename,
            event: event
  end

  def add_responses(assignee_id, filenames)
    self.add_responses!(assignee_id, filenames)
  rescue Statesman::TransitionFailedError, Statesman::GuardFailedError
    false
  end

  def assign_responder!(assigner_id, assignee_id)
    trigger! :assign_responder,
             assignee_id: assignee_id,
             user_id:     assigner_id,
             event:       :assign_responder
  end

  def assign_responder(assigner_id, assignee_id)
    self.assign_responder!(assigner_id, assignee_id)
  rescue Statesman::TransitionFailedError, Statesman::GuardFailedError
    false
  end

  def reject_responder_assignment!(assignee_id, message, assignment_id)
    trigger! :reject_responder_assignment,
             assignee_id: assignee_id,
             user_id:     assignee_id,
             message:     message,
             assignment_id: assignment_id,
             event:       :reject_responder_assignment
  end

  def reject_responder_assignment(assignee_id, message, assignment_id)
    self.reject_responder_assignment!(assignee_id, message, assignment_id)
  rescue Statesman::TransitionFailedError, Statesman::GuardFailedError
    false
  end

  def accept_responder_assignment!(assignee_id)
    trigger! :accept_responder_assignment,
             assignee_id: assignee_id,
             user_id:     assignee_id,
             event:       :accept_responder_assignment
  end

  def accept_responder_assignment(assignee_id)
    self.accept_responder_assignment!(assignee_id)
  rescue Statesman::TransitionFailedError, Statesman::GuardFailedError
    false
  end

  def respond!(assignee_id)
    trigger! :respond,
             assignee_id: assignee_id,
             user_id:     assignee_id,
             event:       :respond
  end

  def respond(assignee_id)
    self.respond!(assignee_id)
  rescue Statesman::TransitionFailedError, Statesman::GuardFailedError
    false
  end

  def close(current_user_id)
    self.close!(current_user_id)
  rescue Statesman::TransitionFailedError, Statesman::GuardFailedError
    false
  end

  def close!(current_user_id)
    trigger! :close,
             user_id:     current_user_id,
             event:       :close
  end
end
