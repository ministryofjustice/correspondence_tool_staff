module Cases
  class TMMStateMachine
    include Statesman::Machine
    include Events

    state :drafting, initial: true
  end
end
