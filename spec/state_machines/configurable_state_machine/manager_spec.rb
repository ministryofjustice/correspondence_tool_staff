require 'rails_helper'

module ConfigurableStateMachine

  describe Manager do

    let(:config_dir)  { Rails.root.join('config/state_machine') }

    describe '.new' do
      it 'is a private method' do
        expect {
          Manager.new
        }.to raise_error NoMethodError, "private method `new' called for ConfigurableStateMachine::Manager:Class"
      end
    end

    describe '.instance' do

      it 'returns an instance of Manager' do
        expect(Manager.instance(config_dir)).to be_instance_of(Manager)
      end

      it 'does not load the configuration twice if called with the same config dir' do
        # the config dir to be read and loaded only once in the entire test suite
        expect(Dir).to receive(:[]).at_most(:once).and_call_original
        Manager.instance(config_dir)
        Manager.instance(config_dir)
      end
    end

    describe '#state_machine' do
      let(:kase) { create :case }
      it 'returns a state machine for the correct org/ct/workflow' do
        manager = Manager.instance(config_dir)
        machine = manager.state_machine(org: 'moj', case_type: 'foi', workflow: 'standard', kase: kase)
        expect(machine).to be_instance_of(Machine)
        config = machine.instance_variable_get(:@config)
        expect(config).to be_instance_of(RecursiveOpenStruct)
        expect(config.to_h.keys).to eq [:initial_state, :user_roles]
      end
    end

  end
end
