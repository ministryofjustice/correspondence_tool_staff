module ConfigurableStateMachine
  # instantiate a ConfigurableStateMachine::Machine on start up. This will
  # force the validation of all state machine configuration file.

  # StateMachineConfigConcatenator.new.run
  # begin
  #   Manager.instance
  # rescue ConfigurationError => e
  #   Rails.logger.debug e.class
  #   Rails.logger.debug e.message
  #   exit # rubocop:disable Rails/Exit
  # end
end
