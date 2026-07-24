require "rails_helper"

describe CaseUpdateAcknowledgementSentService do
  let(:kase) { create :offender_sar_complaint, received_date: 3.weeks.ago.to_date }
  let(:user) { kase.responding_team.users.first }
  let(:team) { kase.responding_team }
  let(:state_machine) do
    double ConfigurableStateMachine::Machine, # rubocop:disable RSpec/VerifiedDoubles
           record_acknowledgement_sent!: true,
           edit_case!: true
  end
  let(:sent_date) { Time.zone.today - 1.week }
  let(:params) do
    {
      acknowledgement_sent_at_dd: sent_date.day.to_s,
      acknowledgement_sent_at_mm: sent_date.month.to_s,
      acknowledgement_sent_at_yyyy: sent_date.year.to_s,
    }
  end
  let(:service) { described_class.new(user:, kase:, params:) }

  before do
    allow(kase).to receive(:state_machine).and_return(state_machine)
    allow(state_machine).to receive(:record_acknowledgement_sent!).with(
      acting_user: user,
      acting_team: team,
      message: nil,
    )
    allow(state_machine).to receive(:edit_case!).with(
      acting_user: user,
      acting_team: team,
      message: anything,
    )
  end

  describe "#call" do
    context "when acknowledgement has not been previously recorded" do
      it "records the acknowledgement sent event" do
        service.call
        expect(state_machine).to have_received(:record_acknowledgement_sent!).with(
          acting_user: user,
          acting_team: team,
          message: nil,
        )
        expect(service.result).to eq :ok
      end

      it "saves the date on the case" do
        service.call
        expect(kase.acknowledgement_sent_at).to eq sent_date
      end
    end

    context "when acknowledgement has already been recorded" do
      let(:old_date) { 2.weeks.ago.to_date }

      before { kase.update!(acknowledgement_sent_at: old_date) }

      it "records an edit_case event with the old and new date in the message" do
        service.call
        expect(state_machine).to have_received(:edit_case!).with(
          acting_user: user,
          acting_team: team,
          message: include(I18n.l(old_date)),
        )
        expect(service.result).to eq :ok
      end
    end

    context "when params are empty (no changes)" do
      let(:params) { {} }

      it "makes no changes and returns :no_changes" do
        service.call
        expect(state_machine).not_to have_received(:record_acknowledgement_sent!)
        expect(state_machine).not_to have_received(:edit_case!)
        expect(service.result).to eq :no_changes
      end
    end

    context "when the date components form an invalid date" do
      let(:params) do
        {
          acknowledgement_sent_at_dd: "31",
          acknowledgement_sent_at_mm: "02",
          acknowledgement_sent_at_yyyy: "2026",
        }
      end

      it "adds an error and returns :error" do
        service.call
        expect(service.result).to eq :error
        expect(kase.errors[:acknowledgement_sent_at]).to be_present
      end
    end

    context "when the date is in the future" do
      let(:future) { Time.zone.today + 1.day }
      let(:params) do
        {
          acknowledgement_sent_at_dd: future.day.to_s,
          acknowledgement_sent_at_mm: future.month.to_s,
          acknowledgement_sent_at_yyyy: future.year.to_s,
        }
      end

      it "fails validation and returns :error" do
        service.call
        expect(service.result).to eq :error
      end
    end
  end
end
