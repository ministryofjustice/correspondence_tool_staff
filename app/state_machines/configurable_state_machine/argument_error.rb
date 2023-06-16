module ConfigurableStateMachine
  class ArgumentError < RuntimeError
    def initialize(kase:, event:, params:)
      super "Invalid params when triggering #{event} on case #{kase.id}: #{params.inspect}"
    end
  end
end
