require "rails_helper"

describe CaseReopenService do
  describe "#call" do
    let(:team)          { find_or_create :team_branston }
    let(:user)          { team.users.first }
    let(:kase)          { create :offender_sar_complaint, :closed }
    let(:state_machine) { double ConfigurableStateMachine::Machine, reopen!: true }

    before do
      @service = described_class.new(user, kase, external_deadline: Date.today)
      allow(kase).to receive(:state_machine).and_return(state_machine)
    end

    context "reopen a offender complaint case" do
      it "default result" do
        expect(@service.result).to eq :incomplete
      end

      it "changes the attributes on the case" do
        allow(kase).to receive(:current_state).and_return("to_be_assessed")
        allow(state_machine).to receive(:reopen!).with(acting_user: user, acting_team: team)
        @service.call
        expect(state_machine).to have_received(:reopen!).with(acting_user: user, acting_team: team)
        expect(kase.date_responded).to eq nil
        expect(@service.result).to eq :ok
      end
    end

    context "if anything fails in the transaction" do
      it "raises an error when it saves" do
        @service.call
        expect(@service.result).to eq :error
      end
    end
  end
end
