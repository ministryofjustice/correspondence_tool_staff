require "rails_helper"

describe StateSelector do
  let(:form_params) do
    ActionController::Parameters.new({
      "state_selector" => {
        "unassigned" => "1",
        "awaiting_responder" => "1",
        "drafting" => "0",
        "awaiting_dispatch" => "0",
        "pending_dacu_clearance" => "1",
        "pending_press_office_clearance" => "0",
        "pending_private_office_clearance" => "0",
        "responded" => "0",
        "closed" => "0",
      },
      "states" => "pending_press_office_clearance,pending_dacu_clearance,drafting",
      "timeliness" => "in_time",
      "other_param" => "other_value",
      "controller" => "cases",
      "orig_action" => "open_cases",
      "commit" => "Filter",
      "action" => "filter",
    })
  end

  let(:url_params) do
    ActionController::Parameters.new(
      {
        "states" => "pending_press_office_clearance,pending_dacu_clearance,drafting",
        "timeliness" => "late",
        "other_param" => "123",
      },
    )
  end

  describe ".new" do
    context "params submitted via form" do
      it "uses state selector params and ignores states" do
        ss = described_class.new form_params
        expect(ss.selected_states).to eq %i[unassigned awaiting_responder pending_dacu_clearance]
      end
    end

    context "params submitted via url" do
      it "generates selected states from states url param" do
        ss = described_class.new url_params
        expect(ss.selected_states).to eq %i[pending_press_office_clearance pending_dacu_clearance drafting]
      end
    end
  end

  describe "retrieving set states" do
    let(:ss) { described_class.new url_params }

    it "returns true if state has been set" do
      expect(ss.pending_press_office_clearance).to be true
    end

    it "returns false if state has not been set" do
      expect(ss.unassigned).to be false
    end

    it "raises method missing if unknown state is queried" do
      expect {
        ss.awaiting_drafting
      }.to raise_error NoMethodError, /undefined method `awaiting_drafting'/
    end
  end

  describe "states_for_url" do
    it "returns selected states as a comma separated string" do
      ss = described_class.new form_params
      expect(ss.states_for_url).to eq "unassigned,awaiting_responder,pending_dacu_clearance"
    end
  end
end
