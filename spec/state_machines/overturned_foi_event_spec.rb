require "rails_helper"

describe "Overturned FOI events" do
  # Overturned FOI cases use the same state machine as regular FOI cases, so wer're not
  # going to to repeat all the FOI tests here, just test that the same config is loaded
  # for and Overturned FOI case as for a regular FOI case.

  describe "state machine" do
    let(:ovt_foi)     { create :overturned_ico_foi }
    let(:foi)         { create :foi_case }

    describe "state_machine_name" do
      it "uses the same state machine name for ovt fois and regular fois" do
        expect(ovt_foi.class.state_machine_name).to eq foi.class.state_machine_name
      end
    end

    describe "state_machine_config" do
      let(:foi_ovt_state_machine_config)    { ovt_foi.state_machine.instance_variable_get(:@config) }
      let(:ovt_state_machine_config)        { foi.state_machine.instance_variable_get(:@config) }

      it "uses the same config" do
        expect(foi_ovt_state_machine_config).to eq ovt_state_machine_config
      end
    end
  end
end
