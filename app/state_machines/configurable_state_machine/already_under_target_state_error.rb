module ConfigurableStateMachine
  class AlreadyUnderTargetStateError < RuntimeError

    def initialize(role:, kase:, user:, event:, target_state:, message: nil)
      description = <<~EOS

        Already under target state : 
                       type: #{kase.type_abbreviation}
                       workflow: #{kase.workflow}
                       role: #{role}
                       state: #{kase.current_state}
                       target_state: #{target_state}
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

