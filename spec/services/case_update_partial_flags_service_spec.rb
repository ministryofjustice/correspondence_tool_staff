require "rails_helper"

describe CaseUpdatePartialFlagsService do
  describe "#call" do
    let(:kase)    { create :offender_sar_case, :closed }
    let(:user)    { kase.responding_team.users.first }
    let(:team)    { kase.responding_team }
    let(:state_machine) do
      double ConfigurableStateMachine::Machine,
             teams_that_can_trigger_event_on_case: [team],
             mark_as_partial_case!: true,
             mark_as_awaiting_response_for_partial_case!: true,
             mark_as_further_actions_required!: true
    end

    before do
      allow(kase).to receive(:state_machine).and_return(state_machine)
      allow(state_machine).to receive(:teams_that_can_trigger_event_on_case!).with(
        event_name: "mark_as_partial_case",
        user:,
      ).and_return([team])
      allow(state_machine).to receive(:mark_as_partial_case!).with(
        acting_user: user,
        acting_team: team,
      )
      allow(state_machine).to receive(:mark_as_further_actions_required!).with(
        acting_user: user,
        acting_team: team,
      )
      allow(state_machine).to receive(:unmark_as_partial_case!).with(
        acting_user: user,
        acting_team: team,
      )
      allow(state_machine).to receive(:unmark_as_further_actions_required!).with(
        acting_user: user,
        acting_team: team,
      )
      allow(state_machine).to receive(:mark_as_awaiting_response_for_partial_case!).with(
        acting_user: user,
        acting_team: team,
      )
    end

    context "Mark the partial case flags" do
      it "Mark as partial case and requiring further actions" do
        flags = { "is_partial_case" => "true", "further_actions_required" => "yes" }
        service = described_class.new(user:, kase:, flag_params: flags)
        expect(service.result).to eq :incomplete

        service.call
        expect(state_machine).to have_received(:mark_as_partial_case!).with(
          acting_user: user,
          acting_team: team,
        )
        expect(state_machine).to have_received(:mark_as_further_actions_required!).with(
          acting_user: user,
          acting_team: team,
        )
        expect(service.result).to eq :ok
      end

      it "Mark as partial case and waiting for response" do
        flags = { "is_partial_case" => "true",
                  "further_actions_required" => "awaiting_response",
                  "partial_case_letter_sent_dated" => Time.zone.today }
        service = described_class.new(user:, kase:, flag_params: flags)
        expect(service.result).to eq :incomplete

        service.call
        expect(state_machine).to have_received(:mark_as_partial_case!).with(
          acting_user: user,
          acting_team: team,
        )
        expect(state_machine).to have_received(:mark_as_awaiting_response_for_partial_case!).with(
          acting_user: user,
          acting_team: team,
        )
        expect(kase.partial_case_letter_sent_dated).to eq flags["partial_case_letter_sent_dated"]
        expect(service.result).to eq :ok
      end
    end

    context "Unmark the partial case flags" do
      it "Unmark as partial case and requiring further actions" do
        kase.update!(is_partial_case: true, further_actions_required: "yes")
        kase.reload

        flags = { "is_partial_case" => "false", "further_actions_required" => "no" }
        service = described_class.new(user:, kase:, flag_params: flags)
        expect(service.result).to eq :incomplete

        service.call
        expect(state_machine).to have_received(:unmark_as_partial_case!).with(
          acting_user: user,
          acting_team: team,
        )
        expect(state_machine).to have_received(:unmark_as_further_actions_required!).with(
          acting_user: user,
          acting_team: team,
        )
        expect(service.result).to eq :ok
      end
    end
  end
end
