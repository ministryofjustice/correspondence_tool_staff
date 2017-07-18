require 'rspec/expectations'

RSpec::Matchers.define :transition_from do |from_state|
  match do |event|
    expect(event[:transitions]).to have_key from_state.to_s
    target_states = event[:transitions][from_state.to_s]
    states = target_states.map { |s| s[:state] }
    expect(states).to include @to_state
    unless @case_policy.nil?
      user_id = spy('user_id')
      user    = stubbed_out_user_for_id(user_id)
      kase    = case_with_stubbed_out_policy(@case_policy, user)

      state_info = target_states.find { |si| si[:state] == @to_state }
      guards     = state_info[:guards]
      options    = { user_id: user_id}
      guards.each { |g| g.call(kase, spy('last_transition'), options) }
    else
      true
    end
  end

  chain :to do |to_state|
    @to_state = to_state.to_s
  end

  chain :checking_case_policy do |policy|
    @case_policy = policy
  end

  def stubbed_out_user_for_id(user_id)
    user = spy('user')
    expect(User).to receive(:find).with(user_id).and_return(user)
    user
  end

  def case_with_stubbed_out_policy(policy_name, user)
    kase = spy('case')
    allow(kase).to receive(:policy_class).and_return(CasePolicy)
    policy = instance_spy(CasePolicy)
    expect(policy).to receive(policy_name)
    expect(CasePolicy).to receive(:new).with(user, kase).and_return(policy)
    kase
  end
end
