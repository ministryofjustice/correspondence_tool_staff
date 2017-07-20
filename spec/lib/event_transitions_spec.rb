require 'rails_helper'

describe Events do
  let(:machine) do
    Class.new do
      include Statesman::Machine
      include Events
    end
  end
  let(:my_model) { Class.new { attr_accessor :current_state }.new }
  let(:instance) { machine.new(my_model) }

  describe '#initialize' do
    it 'instance_evals the given block' do
      self_event_transition = nil
      block = ->(_) { self_event_transition = self }
      returned_event_transition = EventTransitions.new(machine, :test, &block)
      expect(returned_event_transition).to eq self_event_transition
    end
  end

  describe '#transition' do
    let(:event_transition) { EventTransitions.new(machine, :test) {} }

    before do
      allow(machine).to receive(:transition).with(any_args)
    end

    it 'creates transition in the state machine' do
      event_transition.transition(from: :from_state, to: :to_state)
      expect(machine).to have_received(:transition)
                           .with(from: 'from_state', to: 'to_state')
    end

    it 'creates an event transition' do
      event_transition.transition(from: :from_state, to: :to_state)
      expect(machine.events[:test][:transitions]['from_state'].first[:state])
        .to eq 'to_state'
    end

    it 'adds the guard' do
      event_transition.transition from: :from_state,
                                  to: :to_state,
                                  guard: :a_guard
      expect(machine.events[:test][:transitions]['from_state'].first[:guards])
        .to include :a_guard
    end

    it 'creates a guard for a given policy ' do
      user = instance_double(User)
      allow(User).to receive(:find).with(:a_user_id).and_return(user)
      kase = instance_double(Case)
      policies = spy(ApplicationPolicy, a_policy: true)
      allow(Pundit).to receive(:policy!).and_return(policies)

      event_transition.transition from: :from_state,
                                  to: :to_state,
                                  policy: :a_policy
      state_info = machine.events[:test][:transitions]['from_state'].first
      guard = state_info[:guards].first
      guard.call(kase, :last_transition, { user_id: :a_user_id })

      expect(Pundit).to have_received(:policy!).with(user, kase)
      expect(policies).to have_recieved(:a_policy)
    end

    it 'creates a guard automatically if a case policy exists' do
      user = instance_double(User)
      allow(User).to receive(:find).with(:a_user_id).and_return(user)
      kase = instance_double(Case)
      policy_name = :test_from_from_state_to_to_state?
      policies = spy('PunditPolicy', policy_name => true)
      allow(Pundit).to receive(:policy!).and_return(policies)
      allow(CasePolicy).to receive(:instance_methods).and_return([policy_name])

      event_transition.transition from: :from_state,
                                  to: :to_state
      state_info = machine.events[:test][:transitions]['from_state'].first
      guard = state_info[:guards].first
      guard.call(kase, :last_transition, { user_id: :a_user_id })

      expect(Pundit).to have_received(:policy!).with(user, kase)
      expect(policies).to have_recieved('test_from_from_state_to_to_state')
    end

  end
end
