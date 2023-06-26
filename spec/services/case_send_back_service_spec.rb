require "rails_helper"

describe CaseSendBackService do
  describe "#call" do
    let(:state_machine) do
      double ConfigurableStateMachine::Machine, # rubocop:disable RSpec/VerifiedDoubles
             send_back!: true,
             add_message_to_case!: true
    end

    context "when send back a foi case" do
      it "a non-trigger foi case" do
        kase = create :responded_case
        user = kase.managing_team.users.first
        team = kase.managing_team
        service = described_class.new(user:, kase:, comment: "send back")
        expect(service.result).to eq :incomplete

        allow(kase).to receive(:state_machine).and_return(state_machine)
        allow(state_machine).to receive(:add_message_to_case!).with(
          acting_user: user,
          acting_team: team,
          message: "send back",
          disable_hook: true,
        )
        allow(state_machine).to receive(:send_back!).with(acting_user: user, acting_team: team)

        service.call
        expect(state_machine).to have_received(:add_message_to_case!).with(
          acting_user: user,
          acting_team: team,
          message: "send back",
          disable_hook: true,
        )
        expect(state_machine).to have_received(:send_back!).with(acting_user: user, acting_team: team)
        expect(service.result).to eq :ok
      end

      it "a trigger foi case" do
        kase = create :responded_case, :flagged
        user = kase.managing_team.users.first
        team = kase.managing_team
        service = described_class.new(user:, kase:, comment: "send back")
        expect(service.result).to eq :incomplete

        allow(kase).to receive(:state_machine).and_return(state_machine)
        allow(state_machine).to receive(:add_message_to_case!).with(
          acting_user: user,
          acting_team: team,
          message: "send back",
          disable_hook: true,
        )
        allow(state_machine).to receive(:send_back!).with(acting_user: user, acting_team: team)

        service.call
        expect(state_machine).to have_received(:add_message_to_case!).with(
          acting_user: user,
          acting_team: team,
          message: "send back",
          disable_hook: true,
        )
        expect(state_machine).to have_received(:send_back!).with(acting_user: user, acting_team: team)
        expect(service.result).to eq :ok
      end
    end

    context "when send back case with invalid params" do
      it "raises an error when it saves" do
        kase = create :accepted_case
        user = kase.managing_team.users.first
        service = described_class.new(user:, kase:, comment: "send back")
        expect(service.result).to eq :incomplete

        service.call
        expect(service.result).to eq :error
      end
    end
  end
end
