require "rails_helper"

describe CaseValidateRejectedOffenderSARService do
  describe "#call" do
    let(:team) { find_or_create :team_branston }
    let(:user) { find_or_create :branston_user }
    let(:kase) { create :offender_sar_case, :rejected, received_date: 1.day.ago.to_date }
    let(:service) do
      described_class.new(user:,
                          kase:,
                          params:)
    end

    context "when setting a valid date" do
      let(:params) { { received_date: Time.zone.today } }

      it "changes the received date on the case" do
        service.call
        expect(kase.received_date).to eq Time.zone.today
      end

      it "transitions the cases state" do
        expect(kase.state_machine).to receive(:validate_rejected_case!).with({ acting_user: user,
                                                                               acting_team: team,
                                                                               message: nil })

        service.call
        expect(service.result).to eq :ok
      end

      it "removes the 'R' from the case number" do
        service.call
        expect(kase.number[0]).not_to eq "R"
      end

      it "sets the case number using date_received and iteration" do
        service.call
        kase_number = "#{kase.received_date.strftime('%Y%m%d')[2..]}001"
        expect(kase.number).to eq kase_number
      end

      it "updates the deadline" do
        expect {
          service.call
        }.to change(kase, :external_deadline)
      end

      it "sets results to :ok" do
        service.call
        expect(service.result).to eq :ok
      end
    end

    context "when anything fails in the transaction" do
      let(:params) { { received_date: "" } }

      it "raises an error when it saves" do
        service.call
        expect(service.result).to eq :error
      end
    end

    context "when received_date doesn't change" do
      let(:params) { { received_date: kase.received_date } }

      it "updates the deadline" do
        expect {
          service.call
        }.to change(kase, :external_deadline)
      end
    end
  end
end
