module ConfigurableStateMachine
  class InvalidEventError < RuntimeError
    def initialize(role:, kase:, user:, event:, message: nil)
      description = <<~EOS

        Invalid event: type: #{kase.type_abbreviation}
                       workflow: #{kase.workflow}
                       role: #{role}
                       state: #{kase.current_state}
                       event: #{event}
                       kase_id: #{kase.id}
                       user_id: #{user.id}
      EOS
      if message
        description += "               message: #{message}\n"
      end
      super(description)
    end
  end
end
