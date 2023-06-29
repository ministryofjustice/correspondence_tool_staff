require "rails_helper"

describe CaseUnflagForClearanceService do
  let(:assigned_case)         { create :assigned_case }
  let(:assigned_flagged_case) do
    create :assigned_case,
           :flagged_accepted,
           :dacu_disclosure
  end

  let(:press_flagged_case) do
    create :assigned_case,
           :flagged_accepted,
           :press_office
  end
  let(:approver)              { dacu_disclosure.approvers.first }
  let(:team_dacu)             { find_or_create :team_dacu }
  let(:dacu_disclosure)       { find_or_create :team_dacu_disclosure }
  let(:press_office)          { find_or_create :team_press_office }

  describe "call" do
    context "when case is flagged" do
      let(:service) do
        described_class.new user: approver,
                            kase: assigned_flagged_case,
                            team: dacu_disclosure,
                            message: "message"
      end

      before do
        allow(assigned_flagged_case.state_machine)
          .to receive(:unflag_for_clearance!)
        service.call
      end

      it "triggers an event on the case state machine" do
        expect(assigned_flagged_case.state_machine)
          .to have_received(:unflag_for_clearance!)
                .with(acting_user: approver,
                      acting_team: dacu_disclosure,
                      target_team: dacu_disclosure,
                      message: "message")
      end

      it "removes the approving team assignment" do
        expect(assigned_flagged_case.approving_teams).to be_blank
      end

      it "sets the result to ok and returns true" do
        expect(service.result).to eq :ok
      end
    end

    context "when anything fails in the transaction" do
      let(:service) do
        described_class.new user: approver,
                            kase: assigned_flagged_case,
                            team: dacu_disclosure,
                            message: "message"
      end

      it "passes through an error on saves and does not change assignments" do
        all_assignments = assigned_flagged_case.assignments
        allow(assigned_flagged_case.state_machine)
            .to receive(:unflag_for_clearance!)
                    .and_raise(RuntimeError)

        expect {
          service.call
        }.to raise_error(RuntimeError)
        expect(service.result).to eq :error
        expect(assigned_flagged_case.assignments).to eq all_assignments
      end
    end
  end
end
