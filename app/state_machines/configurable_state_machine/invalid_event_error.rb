module ConfigurableStateMachine
  class InvalidEventError < RuntimeError

    def initialize(role:, kase:, user:, event:)
      super("\nInvalid event: type: #{kase.type_abbreviation}\n" +
            "               workflow: #{kase.workflow}\n" +
            "               role: #{role}\n" +
            "               state: #{kase.current_state}\n" +
            "               event: #{event}\n" +
            "               kase_id: #{kase.id}\n" +
            "               user_id: #{user.id}")
    end

  end
end


