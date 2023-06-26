require "rails_helper"

describe CaseRequireFurtherActionService do
  describe "#call" do
    let(:kase)          { create :responded_ico_foi_case }
    let(:user)          { kase.responding_team.users.first }
    let(:team)          { kase.responding_team }
    let(:managing_team) { kase.managing_team }
    let(:state_machine) do
      double ConfigurableStateMachine::Machine, # rubocop:disable RSpec/VerifiedDoubles
             teams_that_can_trigger_event_on_case: [managing_team],
             require_further_action!: true,
             require_further_action_to_responder_team!: true,
             require_further_action_unassigned!: true
    end

    context "when require further action for ico (FOI) with valid parameters" do
      it "Same responder" do
        params = {
          "message": "require further action",
          "internal_deadline": Time.zone.today + 1.day,
          "external_deadline": Time.zone.today + 10.days,
        }
        service = described_class.new(user, kase, params)
        expect(service.result).to eq :incomplete

        allow(kase).to receive(:state_machine).and_return(state_machine)
        allow(state_machine).to receive(:teams_that_can_trigger_event_on_case!).with(
          event_name: "require_further_action",
          user:,
        ).and_return([managing_team])
        allow(state_machine).to receive(:require_further_action!).with(
          acting_user: user,
          acting_team: managing_team,
          message: I18n.t("event.case/ico.require_further_action_message"),
          target_team: team,
        )

        service.call
        expect(state_machine).to have_received(:require_further_action!).with(
          acting_user: user,
          acting_team: managing_team,
          message: I18n.t("event.case/ico.require_further_action_message", team: team.name),
          target_team: team,
        )
        expect(service.result).to eq :ok
      end

      it "Same responder team if responder has been deactivated" do
        params = {
          "message": "require further action",
          "internal_deadline": Time.zone.today + 1.day,
          "external_deadline": Time.zone.today + 10.days,
        }
        service = described_class.new(user, kase, params)
        expect(service.result).to eq :incomplete

        allow(kase).to receive(:state_machine).and_return(state_machine)
        allow(state_machine).to receive(:teams_that_can_trigger_event_on_case!).with(
          event_name: "require_further_action_to_responder_team",
          user:,
        ).and_return([managing_team])
        allow(state_machine).to receive(:require_further_action_to_responder_team!).with(
          acting_user: user,
          acting_team: managing_team,
          message: I18n.t("event.case/ico.require_further_action_to_responder_team_message", team: team.name),
          target_team: team,
        )

        kase.responder.soft_delete
        service.call
        expect(state_machine).to have_received(:require_further_action_to_responder_team!).with(
          acting_user: user,
          acting_team: managing_team,
          message: I18n.t("event.case/ico.require_further_action_to_responder_team_message", team: team.name),
          target_team: team,
        )
        expect(service.result).to eq :ok
      end

      it "Need to reassigned if the responding_team has been deactivated" do
        params = {
          "message": "require further action",
          "internal_deadline": Time.zone.today + 1.day,
          "external_deadline": Time.zone.today + 10.days,
        }
        service = described_class.new(user, kase, params)
        expect(service.result).to eq :incomplete

        allow(kase).to receive(:state_machine).and_return(state_machine)
        allow(state_machine).to receive(:teams_that_can_trigger_event_on_case!).with(
          event_name: "require_further_action_unassigned",
          user:,
        ).and_return([managing_team])
        allow(state_machine).to receive(:require_further_action_unassigned!).with(
          acting_user: user,
          acting_team: managing_team,
          message: I18n.t("event.case/ico.require_further_action_unassigned_message"),
          target_team: nil,
        )

        kase.responding_team.update!(deleted_at: Time.current)
        kase.reload
        service.call
        expect(state_machine).to have_received(:require_further_action_unassigned!).with(
          acting_user: user,
          acting_team: managing_team,
          message: I18n.t("event.case/ico.require_further_action_unassigned_message"),
          target_team: nil,
        )
        expect(service.result).to eq :ok
      end
    end

    context "when require further action for ico (FOI) with invalid params" do
      it "raises an error when it saves" do
        params = {
          "message": "require further action",
          "internal_deadline": Time.zone.today + 10.days,
          "external_deadline": Time.zone.today + 1.day,
        }
        service = described_class.new(user, kase, params)
        expect(service.result).to eq :incomplete

        service.call
        expect(service.result).to eq :error
      end
    end
  end
end
