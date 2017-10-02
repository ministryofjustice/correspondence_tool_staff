require 'rails_helper'

describe Events do
  let(:resource_class) do
    Class.new do
      attr_accessor :current_state
    end
  end
  let(:resource)       { resource_class.new }
  let(:instance)       { machine.new(my_model) }
  let(:user)           { create :user }
  let(:machine) do
    Class.new do
      include Statesman::Machine
      include Events

      def current_state
        'start'
      end
    end
  end
  let(:instance) { machine.new(resource) }

  describe "inclusion" do
    context "after Statesman::Machine" do
      specify { expect { machine.events }.to_not raise_error }
    end

    context "without Statesman::Machine" do
      let(:machine) { Class.new { include Events } }

      it "raises a descriptive error" do
        expect { machine.events }.to raise_error(/without Statesman::Machine/)
      end
    end
  end

  describe '.events' do
    specify 'creates a hash with the new event' do
      machine.events[:new_event]
      expect(machine.events).to have_key(:new_event)
    end

    describe 'structure' do
      specify 'has transitions with from-states and to-states array' do
        expect(machine.events[:new_event][:transitions][:from]).to eq []
      end

      specify 'has before transition callbacks' do
        expect(machine.events[:new_event][:callbacks]).to have_key :before
        expect(machine.events[:new_event][:callbacks][:before]).to eq []
      end

      specify 'has after transition callbacks' do
        expect(machine.events[:new_event][:callbacks]).to have_key :after
        expect(machine.events[:new_event][:callbacks][:after]).to eq []
      end

      specify 'has after_commit callbacks' do
        expect(machine.events[:new_event][:callbacks]).to have_key :after_commit
        expect(machine.events[:new_event][:callbacks][:after_commit]).to eq []
      end

      specify 'has guards' do
        expect(machine.events[:new_event][:callbacks]).to have_key :guards
        expect(machine.events[:new_event][:callbacks][:guards]).to eq []
      end
    end
  end

  describe '.event' do
    it 'creates and returns a new EventTransitions' do
      blk = Proc.new {}
      result = machine.event(:new_event, &blk)
      expect(result).to be_a(EventTransitions)
    end
  end

  describe '#trigger!' do
    specify 'raises if the guard fails for the given event' do
      machine.events[:fail_event][:callbacks][:guards] << Proc.new { false }
      expect { instance.trigger!(:fail_event) }
        .to raise_error(Statesman::GuardFailedError)
    end
  end

  describe '#permitted_events' do
    end
  end
end
