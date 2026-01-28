require "rails_helper"

describe CaseRemovePITExtensionService do
  let!(:received_date) { freeze_time { 7.business_days.ago.to_date } }
  let!(:team_dacu)     { find_or_create :team_disclosure_bmt }
  let!(:manager)       { find_or_create :disclosure_bmt_user }

  let(:case_being_drafted) do
    freeze_time do
      create(
        :case_being_drafted,
        :extended_for_pit,
        received_date:,
      )
    end
  end

  let(:service) do
    described_class.new(
      manager,
      case_being_drafted,
    )
  end

  describe "#call" do
    before do
      allow(case_being_drafted.state_machine).to receive(:remove_pit_extension!)
    end

    it "calls extend_for_pit on the case state machine" do
      service.call
      expect(case_being_drafted.state_machine)
        .to have_received(:remove_pit_extension!)
        .with(acting_user: manager,
              acting_team: team_dacu)
    end

    it "sets the external deadline on the case" do
      freeze_time do
        service.call
        expect(case_being_drafted.external_deadline)
          .to eq 20.business_days.after(received_date, holidays: ::BusinessTimeConfig.additional_bank_holidays)
      end
    end

    it "sets result to :ok and returns same" do
      result = service.call
      expect(result).to eq :ok
      expect(service.result).to eq :ok
    end
  end
end
