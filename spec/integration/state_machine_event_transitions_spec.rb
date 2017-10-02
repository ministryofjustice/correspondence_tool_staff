require "rails_helper"

feature 'state machine events and transitions' do
  class TestModel
  end

  class TestModelPolicy
    def initialize(*_args)
    end
  end

  class TestStateMachine
    include Statesman::Machine
    include Events

    state :x, initial: true
    state :y
    state :z

    event :event_1 do
      transition from: :x, to: :y
    end

    event :event_2 do
      transition from: :y, to: :z
    end

    event :event_3 do
      guard { false }
      transition from: :x, to: :y
    end
  end

  let(:resource)      { TestModel.new }
  let(:state_machine) { TestStateMachine.new(resource) }
  let(:user)          { create :user }
  let(:metadata)      { { acting_user_id: user.id } }

  describe 'events' do

    context 'when the state cannot be transitioned to' do
      it 'raises an error' do
        expect { state_machine.trigger!(:event_2) }.
          to raise_error(Statesman::TransitionFailedError)
      end
    end

    context "when the state can be transitioned to" do
      it "changes state" do
        state_machine.trigger!(:event_1, acting_user_id: user.id)
        expect(state_machine.current_state).to eq("y")
      end

      it "creates a new transition object" do
        expect { state_machine.trigger!(:event_1, acting_user_id: user.id) }.
          to change(state_machine.history, :count).by(1)

        expect(state_machine.history.first).
          to be_a(Statesman::Adapters::MemoryTransition)
        expect(state_machine.history.first.to_state).to eq("y")
      end

      it "sends metadata to the transition object" do
        meta = { "my" => "hash", acting_user_id: user.id }
        state_machine.trigger!(:event_1, meta)
        expect(state_machine.history.first.metadata).to eq(meta)
      end

      # it "sets an empty hash as the metadata if not specified" do
      #   state_machine.trigger!(:event_1, acting_user_id: user.id)
      #   expect(state_machine.history.first.metadata).to eq({})
      # end

      it "returns true" do
        expect(state_machine.trigger!(:event_1, acting_user_id: user.id))
          .to eq(true)
      end

      context "with a guard" do
        let(:result) { true }
        # rubocop:disable UnusedBlockArgument
        let(:guard_cb) { ->(*args) { result } }
        # rubocop:enable UnusedBlockArgument

        before do
          TestStateMachine.guard_transition(from: :x, to: :y, &guard_cb)
        end

        context "and an object to act on" do
          # let(:state_machine) { TestStateMachine.new() }

          it "passes the object to the guard" do
            expect(guard_cb).to receive(:call).once.
                                  with(resource,
                                       state_machine.last_transition,
                                       { acting_user_id: user.id})
                                  .and_return(true)
            state_machine.trigger!(:event_1, acting_user_id: user.id)
          end
        end

        context "which passes" do
          it "changes state" do
            expect do
              state_machine.trigger!(:event_1,acting_user_id: user.id)
            end.to change { state_machine.current_state }.to("y")
          end
        end

        context "which fails" do
          let(:result) { false }

          it "raises an exception" do
            expect do
              state_machine.trigger!(:event_1, acting_user_id: user.id) 
            end.to raise_error(Statesman::GuardFailedError)
          end
        end
      end
    end  end
end
