require "rails_helper"

describe CaseUpdaterService do
  describe "#call" do
    let(:team)          { find_or_create :team_dacu }
    let(:user)          { team.users.first }
    let(:kase)          { create :accepted_case }
    let(:state_machine) { double ConfigurableStateMachine::Machine, edit_case!: true } # rubocop:disable RSpec/VerifiedDoubles
    let(:service)       { described_class.new(user, kase, params) }

    before do
      allow(kase).to receive(:state_machine).and_return(state_machine)
    end

    context "when we have different params (i.e user edited data)" do
      let(:params)        { { name: "Joe Blogg" } }

      it "changes the attributes on the case" do
        service.call
        expect(kase.name).to eq "Joe Blogg"
      end

      it "transitions the cases state" do
        expect(state_machine).to receive(:edit_case!).with(acting_user: user, acting_team: team, message: nil)
        service.call
      end

      it "sets results to :ok" do
        service.call
        expect(service.result).to eq :ok
      end
    end

    context "when all the params are the same(i.e user has not edited data)" do
      let(:params)        { { name: kase.name } }

      it "does not change the attributes on the case" do
        service.call
        expect(kase.name).to eq kase.name
      end

      it "does not transitions the cases state" do
        expect(state_machine).not_to receive(:edit_case!)
        service.call
      end

      it "sets results to :no_changes" do
        service.call
        expect(service.result).to eq :no_changes
      end
    end

    context "when anything fails in the transaction" do
      let(:params) { { name: "Joe bloggs" } }

      it "raises an error when it saves" do
        allow(kase).to receive(:save).and_raise(RuntimeError)
        service.call
        expect(service.result).to eq :error
      end
    end
  end
end
