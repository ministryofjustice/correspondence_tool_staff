require "rspec/expectations"

RSpec::Matchers.define :transition_from do |from_state|
  def check_target_states(target_states)
    states = target_states.map { |s| s[:state] }
    if states.include? @to_state
      true
    else
      @error = "#{@to_state} not found in target states"
      false
    end
  end

  def check_to_state_populated
    if @to_state.nil?
      @error = "cannot check default policy without to_state"
      false
    else
      true
    end
  end

  def check_policy_exists_in_policy_class
    if @policy_class.respond_to? @check_policy.to_sym
      true
    else
      @error = "policy class #{@policy_class} does not have policy method " \
               + @check_policy.to_s
      false
    end
  end

  def check_transition_exists(from_state, transitions)
    if transitions.key? from_state.to_s
      true
    else
      @error = "transition from state #{from_state} does not exist"
      false
    end
  end

  def raise_expectation_failed
    raise(RSpec::Expectations::ExpectationNotMetError, @error)
  end

  match do |event_name|
    state_machine_class = state_machine_name.constantize
    event = state_machine_class.events[event_name]

    check_transition_exists(from_state, event[:transitions]) ||
      raise_expectation_failed
    target_states = event[:transitions][from_state.to_s]
    check_target_states(target_states) || raise_expectation_failed

    return true if @check_policy.nil? && !@check_default_policy

    if @check_default_policy
      check_to_state_populated || raise_expectation_failed
      @check_policy = "#{event_name}_from_#{from_state}_to_#{@to_state}?"
    end

    user_id = spy("user_id")
    user    = stubbed_out_user_for_id(user_id)
    object  = object_with_stubbed_out_policy(@check_policy, user)

    state_info = target_states.find { |si| si[:state] == @to_state }
    guards     = state_info[:guards]
    options    = { acting_user_id: user_id }
    guards.each { |g| g.call(object, spy("last_transition"), options) }
  end

  chain :to do |to_state|
    @to_state = to_state.to_s
  end

  chain :checking_default_policy do |policy_class = nil|
    @policy_class = policy_class || default_policy_class
    @check_default_policy = true
  end

  chain :checking_policy do |policy, policy_class = nil|
    @policy_class = policy_class || default_policy_class
    @check_policy = policy
  end

  failure_message do |event_name|
    @error ||= "unknown error"
    "Expected event #{event_name} to transition from state #{from_state}: #{@error}"
  end

  def stubbed_out_user_for_id(user_id)
    user = spy("user")
    allow(User).to receive(:find).with(user_id).and_return(user)
    user
  end

  def object_with_stubbed_out_policy(policy_name, user)
    object = spy("object")
    allow(object).to receive(:policy_class).and_return(@policy_class)
    policy = spy(@policy_class)
    expect(policy).to receive(policy_name)
    expect(@policy_class).to receive(:new).with(user, object).and_return(policy)
    object
  end

  def state_machine_name
    RSpec.current_example.example_group.top_level_description
  end

  def default_policy_class
    state_machine_name.sub("StateMachine", "Policy").constantize
  end
end
