require 'rails_helper'

describe Events do
  class TestStateMachine
    include Statesman::Machine
    include Events
  end

  class Model
    attr_accessor :current_state
  end

  class ModelPolicy
    def initialize(_user, _object)
    end

    def can_test_policy?
      true
    end

    def test_from_from_state_to_to_state?
      true
    end
  end

  let(:object) { Model.new }
  let(:instance) { TestStateMachine.new(object) }
  let(:guard) do
    state_info = TestStateMachine
                   .events[:test][:transitions]['from_state']
                   .first
    state_info[:guards].first
  end

  describe '#initialize' do
    it 'instance_evals the given block' do
      self_event_transition = nil
      block = ->(_) { self_event_transition = self }
      returned_event_transition = EventTransitions
                                    .new(TestStateMachine, :test, &block)
      expect(returned_event_transition).to eq self_event_transition
    end
  end

  describe '#transition' do
    let(:user) { create :user }
    let(:event_transition) { EventTransitions.new(TestStateMachine, :test) {} }

    before do
      allow(TestStateMachine).to receive(:transition).with(any_args)
    end

    after do
      TestStateMachine.events.clear
    end

    it 'creates transition in the state machine' do
      event_transition.transition(from: :from_state, to: :to_state)
      expect(TestStateMachine).to have_received(:transition)
                                    .with(from: 'from_state', to: 'to_state')
    end

    it 'creates an event transition' do
      event_transition.transition(from: :from_state, to: :to_state)
      expect(TestStateMachine.events[:test][:transitions]['from_state'].first[:state])
        .to eq 'to_state'
    end

    it 'adds the guard' do
      event_transition.transition from: :from_state,
                                  to: :to_state,
                                  guard: :a_guard
      expect(TestStateMachine.events[:test][:transitions]['from_state'].first[:guards])
        .to include :a_guard
    end

    context 'with a specific policy' do
      describe 'the generated guard' do
        it 'calls the policy returning true if it succeeds' do
          expect_any_instance_of(ModelPolicy)
            .to receive(:can_test_policy?).and_return(true)

          event_transition.transition from: :from_state, to: :to_state,
                                      policy: :can_test_policy?

          expect(
            guard.call(object, :last_transition, { acting_user_id: user.id })
          ).to eq true
        end

        it 'calls the policy returning false if it fails' do
          expect_any_instance_of(ModelPolicy)
            .to receive(:can_test_policy?).and_return(false)

          event_transition.transition from: :from_state, to: :to_state,
                                      policy: :can_test_policy?

          expect(
            guard.call(object, :last_transition, { acting_user_id: user.id })
          ).to eq false
        end

        it 'returns false if the policy method does not exist' do
          event_transition.transition from: :from_state, to: :to_state,
                                      policy: :can_test_missing_policy?

          expect {
            guard.call(object, :last_transition, { acting_user_id: user.id })
          }.to raise_error(NameError, 'Policy can_test_missing_policy? does not exist.')
        end
      end
    end

    context 'without a specific policy' do
      describe 'the generated guard' do
        it 'calls a policy derived from the event and returns true if succeeds' do
          expect_any_instance_of(ModelPolicy)
            .to receive(:test_from_from_state_to_to_state?).and_return(true)

          event_transition.transition from: :from_state, to: :to_state

          expect(
            guard.call(object, :last_transition, { acting_user_id: user.id })
          ).to eq true
        end

        it 'calls a policy derived from the event and returns false if fails' do
          expect_any_instance_of(ModelPolicy)
            .to receive(:test_from_from_state_to_to_state?).and_return(false)

          event_transition.transition from: :from_state, to: :to_state

          expect(
            guard.call(object, :last_transition, { acting_user_id: user.id })
          ).to eq false
        end

        it 'returns true if the derived policy does not exist' do
          event_transition.transition from: :this_state, to: :that_state

          state_info = TestStateMachine
                         .events[:test][:transitions]['this_state']
                         .first
          guard = state_info[:guards].first
          expect(
            guard.call(object, :last_transition, { acting_user_id: user.id })
          ).to eq true
        end
      end
    end
  end
end
