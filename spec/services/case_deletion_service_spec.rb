require "rails_helper"

describe CaseDeletionService do
  describe "#call" do
    let(:team)          { find_or_create :team_dacu }
    let(:user)          { team.users.first }
    let(:kase)          { create :accepted_case }
    let(:state_machine) { double ConfigurableStateMachine::Machine, destroy_case!: true } # rubocop:disable RSpec/VerifiedDoubles
    let(:service)       { described_class.new(user, kase, reason_for_deletion: "Because") }

    context "when soft deleting a case" do
      before do
        allow(kase).to receive(:state_machine).and_return(state_machine)
      end

      it "changes the attributes on the case" do
        service.call
        expect(kase.deleted?).to eq true
      end

      it "transitions the cases state" do
        expect(state_machine).to receive(:destroy_case!).with(acting_user: user, acting_team: team)
        service.call
      end

      it "sets results to :ok" do
        expect(service.call).to eq :ok
      end
    end

    context "when anything fails in the transaction" do
      before do
        allow(kase).to receive(:state_machine).and_return(state_machine)
      end

      it "raises an error when it saves" do
        allow(kase).to receive(:update).and_return(false)
        expect(service.call).to eq :error
      end
    end

    context "when the case state does not permit the destroy_case event" do
      let(:kase) { create :accepted_sar, :stopped }

      it "sets result to :error" do
        expect(service.call).to eq :error
      end

      it "does not soft delete the case" do
        service.call
        expect(kase.reload.deleted?).to eq false
      end

      it "adds an error to the case" do
        service.call
        expect(kase.errors[:base])
          .to include(I18n.t("activerecord.errors.models.case.attributes.base.invalid_deletion_state"))
      end
    end
  end
end
