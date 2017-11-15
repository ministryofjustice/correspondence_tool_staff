module ConfigurableStateMachine
  class InvalidEventError < RuntimeError

    def initialize(kase:, user:, event:)
      super("Invalid Event: '#{event}': case_id: #{kase.id}, user_id: #{user.id}")
    end

  end
end


