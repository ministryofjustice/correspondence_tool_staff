module ConfigurableStateMachine
  class ConfigurationError < RuntimeError
    def initialize(errors)
      super errors.join("\n")
    end
  end
end
