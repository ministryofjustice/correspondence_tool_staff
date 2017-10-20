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
    check_guards_for_event!(event_name, metadata)
    target_state = get_next_target_state_for_event(event_name, metadata)
    unless target_state
      raise Statesman::GuardFailedError,
            "No transitions available for event: #{event_name} " \
            + "with object: #{object} in state: #{object.current_state} " \
            + "and metadata: #{metadata}"
    end
    new_state = target_state.fetch(:state)
    transition_to!(new_state, metadata)
    if target_state.key? :new_workflow
      object.update workflow: target_state[:new_workflow].to_s
    end
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
                         metadata: { acting_user_id: user_id })
    end.map(&:first)
    events.sort! { |a, b| a.to_s <=> b.to_s }
  end

  def next_state_for_event(event_name, metadata = {})
    target_states = get_event_target_states!(event_name)

    to_state_info = target_states.find do |state_info|
      new_state = state_info.fetch(:state)
      guards = state_info.fetch(:guards)
      can_transition_to?(new_state, metadata) &&
        guards.all? { |g| g.call(@object, last_transition, metadata) }
    end
    to_state_info[:state]
  end

  def can_trigger_event?(event_name:, metadata: {})
    event_exists?(event_name) &&
      have_transition_for_event?(event_name) &&
      check_guards_for_event(event_name, metadata) &&
      check_guards_for_event_transitions(event_name, metadata)
  end

  def event_exists?(event_name)
    self.class.events.key? event_name
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

  def check_guards_for_event!(event_name, metadata)
    unless check_guards_for_event(event_name, metadata)
      raise Statesman::GuardFailedError,
            "Guard on event: #{event_name} with object: #{object}" \
            + " metadata: #{metadata} returned false"
    end
  end

  def have_transition_for_event?(event_name)
    event = get_event!(event_name)
    event.fetch(:transitions).key?(current_state)
  end

  def check_guards_for_event_transitions(event_name, metadata)
    target_state = get_next_target_state_for_event(event_name, metadata)
    return false if target_state.nil?
    can_transition_to?(target_state[:state], metadata)
  end

  def get_next_target_state_for_event(event_name, metadata)
    target_states = get_event_target_states!(event_name)
    target_states.find do |target_state|
      call_guards_for_target_state(target_state, metadata)
    end
  end

  def call_guards_for_target_state(target_state, metadata)
    guards = target_state[:guards]
    guards.blank? ||
      guards.all? { |g| g.call(object,last_transition,metadata) }
  end
end
