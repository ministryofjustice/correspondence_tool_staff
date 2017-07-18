require_relative "event_transitions"

# Adds support for events when `extend`ed into state machine classes
module Events
  def self.included(base)
    unless base.respond_to?(:states)
      raise "Statesman::Events included before/without Statesman::Machine"
    end
    base.extend(ClassMethods)
  end

  module ClassMethods
    def events
      @events ||= Hash.new do |events, event_name|
        events[event_name] = {
          transitions: Hash.new { |transitions, from| transitions[from] = [] },
          callbacks: {
            before: [],
            after: [],
            after_commit: [],
            guards: [],
          }
        }
      end
    end

    def event(name, &block)
      EventTransitions.new(self, name, &block)
    end
  end

  def trigger!(event_name, metadata = {})
    event = get_event! event_name

    event[:callbacks][:guards].each do |guard|
      unless guard.call(@object, last_transition, metadata)
        raise Statesman::GuardFailedError,
              "Guard on event: #{event_name} with object: #{@object}" \
              + " metadata: #{metadata} returned false"
      end
    end

    transitions = event.fetch(:transitions).fetch(current_state) do
      raise Statesman::TransitionFailedError,
            "State #{current_state} not found for Event #{event_name}"
    end

    # We have a list of destination states with their guards here, but for the
    # time being we just take the first one. We could, in theory, test the
    # guard for each one and choose the first one that succeeds.
    state_info = transitions.first
    state_info[:guards].each do |guard|
      unless guard.call @object, last_transition, metadata
        raise Statesman::GuardFailedError,
              "Guard on event: #{event_name} with object: #{@object}" \
              + " metadata: #{metadata} returned false"
      end
    end
    new_state = state_info.fetch(:state)

    transition_to!(new_state, metadata)
    true
  end

  def trigger(event_name, metadata = {})
    self.trigger!(event_name, metadata)
  rescue Statesman::TransitionFailedError, Statesman::GuardFailedError
    false
  end

  def available_events
    state = current_state
    self.class.events.select do |_, event|
      event[:transitions].key?(state)
    end.map(&:first)
  end

  def permitted_events(user_id)
    events = self.class.events.select do |event_name, _event|
      can_trigger_event?(event_name: event_name,
                         metadata: { user_id: user_id })
    end.map(&:first)
    events.sort! { |a, b| a.to_s <=> b.to_s }
  end

  def next_state_for_event(event_name)
    target_states = get_event_target_states!(event_name)
    target_states.first.fetch(:state)
  end

  private

  def get_event!(event_name)
    self.class.events.fetch(event_name) do
      raise Statesman::TransitionFailedError,
            "Event #{event_name} not found"
    end
  end

  def get_event_target_states!(event_name)
    event = get_event!(event_name)
    event.fetch(:transitions).fetch(current_state) do
      raise Statesman::TransitionFailedError,
            "State #{current_state} not found for Event #{event_name}"
    end
  end

  def check_guards_for_event(event_name, metadata)
    event = get_event!(event_name)
    event.fetch(:callbacks).fetch(:guards).all? do |guard|
      guard.call(@object, last_transition, metadata)
    end
  end

  def have_transition_for_event?(event_name)
    event = get_event!(event_name)
    event.fetch(:transitions).key?(current_state)
  end

  def check_guards_for_event_transitions(event_name, metadata)
    target_states = get_event_target_states!(event_name)
    target_states.any? do |state_info|
      new_state = state_info.fetch(:state)
      guards = state_info.fetch(:guards)
      can_transition_to?(new_state, metadata) &&
        guards.all? { |g| g.call(@object, last_transition, metadata) }
    end
  end

  def can_trigger_event?(event_name:, metadata: {})
    have_transition_for_event?(event_name) &&
      check_guards_for_event(event_name, metadata) &&
      check_guards_for_event_transitions(event_name, metadata)
  end
end
