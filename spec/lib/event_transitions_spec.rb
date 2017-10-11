require 'rails_helper'

describe Events do
  let(:test_state_machine_class) do
    Class.new do
      include Statesman::Machine
      include Events
    end
  end

  let(:model_class) do
    Class.new do
      attr_accessor :current_state
    end
  end

  let(:model_policy_class) do
    new_policy_class = Class.new do
      def initialize(_user, _object)
      end

      def can_test_policy?
        true
      end

      def test_from_from_state_to_to_state?
        true
      end
    end

    allow_any_instance_of(model_class).to receive(:policy_class)
                                            .and_return(new_policy_class)
    new_policy_class
  end

  let(:object) { model_class.new }
  let(:instance) { test_state_machine_class.new(object) }
  let(:event_transition) { EventTransitions.new(test_state_machine_class,
                                                :test) {} }

  describe '#initialize' do
    it 'instance_evals the given block' do
      self_event_transition = nil
      block = ->(_) { self_event_transition = self }
      returned_event_transition = EventTransitions
                                    .new(test_state_machine_class, :test, &block)
      expect(returned_event_transition).to eq self_event_transition
    end
  end

  describe '#transition' do
    let(:user) { create :user }

    before do
      allow(test_state_machine_class).to receive(:transition).with(any_args)
    end

    after do
      test_state_machine_class.events.clear
    end

    it 'creates transition in the state machine' do
      event_transition.transition(from: :from_state, to: :to_state)
      expect(test_state_machine_class).to have_received(:transition)
                                    .with(from: 'from_state', to: 'to_state')
    end

    it 'creates an event transition' do
      event_transition.transition(from: :from_state, to: :to_state)
      expect(test_state_machine_class.events[:test][:transitions]['from_state'].first[:state])
        .to eq 'to_state'
    end

    it 'adds the workflow to the transition info' do
      event_transition.transition from: :from_state,
                                  to: :to_state,
                                  new_workflow: 'new_workflow'
      expect(test_state_machine_class
               .events[:test][:transitions]['from_state']
               .first[:new_workflow]).to eq 'new_workflow'
    end

    it 'adds the guard' do
      event_transition.transition from:  :from_state,
                                  to:    :to_state,
                                  guard: :a_guard
      expect(test_state_machine_class.events[:test][:transitions]['from_state'].first[:guards])
        .to include :a_guard
    end

    context 'authorizing with the default policy' do
      describe 'the generated guard' do
        let(:guard) do
          state_info = test_state_machine_class
                         .events[:test][:transitions]['from_state']
                         .first
          state_info[:guards].first
        end

        it 'calls the default policy returning true if it succeeds' do
          expect_any_instance_of(model_policy_class)
            .to receive(:test_from_from_state_to_to_state?).and_return(true)

          event_transition.transition from: :from_state, to: :to_state,
                                      authorize: true

          expect(
            guard.call(object, :last_transition, { acting_user_id: user.id })
          ).to eq true
        end

        it 'calls the default policy returning false if it fails' do
          expect_any_instance_of(model_policy_class)
            .to receive(:test_from_from_state_to_to_state?).and_return(false)

          event_transition.transition from: :from_state, to: :to_state,
                                      authorize: true

          expect(
            guard.call(object, :last_transition, { acting_user_id: user.id })
          ).to eq false
        end

        it 'raises if the default policy does not exist' do
          model_policy_class
          event_transition.transition from: :from_state, to: :another_state,
                                      authorize: true

          expect {
            guard.call(object, :last_transition, { acting_user_id: user.id })
          }.to raise_error(NameError,
                           'Policy "test_from_from_state_to_another_state?" ' +
                           'does not exist.')
        end
      end
    end

    context 'authorizing with a specific policy' do
      describe 'the generated guard' do
        let(:guard) do
          state_info = test_state_machine_class
                         .events[:test][:transitions]['from_state']
                         .first
          state_info[:guards].first
        end

        it 'calls the policy returning true if it succeeds' do
          expect_any_instance_of(model_policy_class)
            .to receive(:can_test_policy?).and_return(true)

          event_transition.transition from: :from_state, to: :to_state,
                                      authorize: :can_test_policy?

          expect(
            guard.call(object, :last_transition, { acting_user_id: user.id })
          ).to eq true
        end

        it 'calls the policy returning false if it fails' do
          expect_any_instance_of(model_policy_class)
            .to receive(:can_test_policy?).and_return(false)

          event_transition.transition from: :from_state, to: :to_state,
                                      authorize: :can_test_policy?

          expect(
            guard.call(object, :last_transition, { acting_user_id: user.id })
          ).to eq false
        end

        it 'raises if the policy method does not exist' do
          model_policy_class
          event_transition.transition from: :from_state, to: :to_state,
                                      authorize: :can_test_missing_policy?

          expect {
            guard.call(object, :last_transition, { acting_user_id: user.id })
          }.to raise_error(NameError,
                           'Policy "can_test_missing_policy?" does not exist.')
        end
      end
    end
  end

  describe '#authorize' do
    let(:user) { create :user }
    let(:guard) do
      state_info = test_state_machine_class
                     .events[:test][:transitions]['auth']
                     .first
      state_info[:guards].first
    end

    it 'sets the policy for new transitions' do
      allow(test_state_machine_class).to receive(:transition).with(any_args)
      event_transition.authorize :authorize_this?
      expect_any_instance_of(model_policy_class).to receive(:authorize_this?)
                                               .and_return(true)
      event_transition.transition from: :auth, to: :orize
      expect(
        guard.call(object, :last_transition, { acting_user_id: user.id })
      ).to eq true
    end
  end

  describe '#authorize_by_event_name' do
    let(:user) { create :user }
    let(:guard) do
      state_info = test_state_machine_class
                     .events[:test][:transitions]['auth']
                     .first
      state_info[:guards].first
    end

    it 'sets the policy for new transitions' do
      allow(test_state_machine_class).to receive(:transition).with(any_args)
      event_transition.authorize_by_event_name
      expect_any_instance_of(model_policy_class).to receive(:test?)
                                                      .and_return(true)
      event_transition.transition from: :auth, to: :orize
      expect(
        guard.call(object, :last_transition, { acting_user_id: user.id })
      ).to eq true
    end

  end
end
