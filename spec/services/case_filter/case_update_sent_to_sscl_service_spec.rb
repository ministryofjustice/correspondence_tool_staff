require "rails_helper"

describe CaseFilter::CaseUpdateSentToSsclService do
  let(:kase) { create :offender_sar_case, :closed }
  let(:user) { kase.responding_team.users.first }
  let(:team) { kase.responding_team }
  let(:reason) { "Not required" }
  let(:state_machine) do
    double ConfigurableStateMachine::Machine,
           record_sent_to_sscl!: true,
           edit_case!: true,
           date_sent_to_sscl_removed!: true
  end
  let(:params) { { sent_to_sscl_at: Date.current - 1.day } }
  let(:service) { CaseUpdateSentToSsclService.new(user:, kase:, params:) }

  before do
    allow(kase).to receive(:state_machine).and_return(state_machine)
    allow(state_machine).to receive(:record_sent_to_sscl!).with(
      acting_user: user,
      acting_team: team,
      message: nil,
    )
    allow(state_machine).to receive(:edit_case!).with(
      acting_user: user,
      acting_team: team,
      message: nil,
    )
    allow(state_machine).to receive(:date_sent_to_sscl_removed!).with(
      acting_user: user,
      acting_team: team,
      message: "(Reason: #{reason})",
    )
  end

  describe "update case" do
    context "when data has not been sent to SSCL" do
      it "records as sent to SSCL" do
        service.call
        expect(state_machine).to have_received(:record_sent_to_sscl!).with(
          acting_user: user,
          acting_team: team,
          message: nil,
        )
        expect(service.result).to eq :ok
      end
    end

    context "when no change made" do
      let(:params) { {} }

      it "does not record as sent to SSCL" do
        service.call
        expect(state_machine).not_to have_received(:record_sent_to_sscl!).with(
          acting_user: user,
          acting_team: team,
          message: nil,
        )
        expect(service.result).to eq :no_changes
      end
    end

    context "when invalid change made" do
      let(:params) { { sent_to_sscl_at: "invalid" } }

      it "does not record as sent to SSCL" do
        service.call
        expect(state_machine).not_to have_received(:record_sent_to_sscl!).with(
          acting_user: user,
          acting_team: team,
          message: nil,
        )
        expect(service.result).to eq :error
        expect(service.message).to be_present
      end
    end

    context "when data has already been sent to SSCL" do
      before { kase.update!(sent_to_sscl_at: Date.current) }

      it "does not record as sent to SSCL" do
        service.call
        expect(state_machine).not_to have_received(:record_sent_to_sscl!).with(
          acting_user: user,
          acting_team: team,
          message: nil,
        )
        expect(service.result).to eq :ok
      end

      it "records a case updated event" do
        service.call
        expect(state_machine).to have_received(:edit_case!).with(
          acting_user: user,
          acting_team: team,
          message: nil,
        )
      end

      context "and sent to SSCL date is being removed" do
        let(:params) { { sent_to_sscl_at: nil, remove_sent_to_sscl_reason: reason } }

        it "records a date removed event" do
          service.call
          expect(state_machine).to have_received(:date_sent_to_sscl_removed!).with(
            acting_user: user,
            acting_team: team,
            message: "(Reason: #{reason})",
          )
        end
      end
    end
  end
end
