class CaseStateMachine
  include Statesman::Machine
  include Statesman::Events

  state :unassigned, initial: true
  state :awaiting_responder
  state :drafting

  event :assign_responder do
    transition from: :unassigned, to: :awaiting_responder
  end

  event :reject_responder_assignment do
    transition from: :awaiting_responder, to: :unassigned
  end

  event :accept_responder_assignment do
    transition from: :awaiting_responder, to: :drafting
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

  def reject_responder_assignment!(assignee_id, message)
    trigger! :reject_responder_assignment,
             assignee_id: assignee_id,
             user_id:     assignee_id,
             message:     message,
             event:       :reject_responder_assignment
  end

  def reject_responder_assignment(assignee_id, message)
    self.reject_responder_assignment!(assignee_id, message)
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
end
