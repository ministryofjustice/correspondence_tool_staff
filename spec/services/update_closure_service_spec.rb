require "rails_helper"

describe UpdateClosureService do
  describe "#call" do
    let(:date_received)         { 7.business_days.ago.to_date }
    let(:new_date_responded)    { 4.business_days.ago.to_date }
    let(:team)                  { find_or_create :team_dacu }
    let(:user)                  { team.users.first }
    let(:kase)                  { create :closed_case, received_date: date_received }
    let(:state_machine)         do
      double ConfigurableStateMachine::Machine,
             update_closure!: true,
             teams_that_can_trigger_event_on_case: [team]
    end

    before do
      @service = described_class.new(kase, user, params)
      allow(kase).to receive(:state_machine).and_return(state_machine)
      allow(state_machine).to receive(:teams_that_can_trigger_event_on_case!).with(
        event_name: "update_closure",
        user:,
      ).and_return([team])
    end

    context "when we have different params (i.e user edited data)" do
      let(:params) do
        {
          date_responded_dd: new_date_responded.day.to_s,
          date_responded_mm: new_date_responded.month.to_s,
          date_responded_yyyy: new_date_responded.year.to_s,
        }
      end

      it "changes the attributes on the case" do
        @service.call
        expect(kase.date_responded).to eq new_date_responded
      end

      it "transitions the cases state" do
        expect(state_machine).to receive(:update_closure!)
                                   .with(acting_user: user, acting_team: team)
        @service.call
      end

      it "sets results to :ok" do
        @service.call
        expect(@service.result).to eq :ok
      end
    end
  end
end
