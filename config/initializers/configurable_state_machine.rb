module ConfigurableStateMachine

  # instantiate a ConfigurableStateMachine::Machine on start up. This will
  # force the validation of all state machine configuration file.

  StateMachineConfigConcatenator.new.run
  begin
    Manager.instance
  rescue ConfigurationError => err
    puts err.class
    puts err.message
    exit
  end
end
