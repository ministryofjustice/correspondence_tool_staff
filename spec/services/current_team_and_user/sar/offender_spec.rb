require "rails_helper"

describe "CurrentTeamAndUserSAROffenderService" do
  let(:team_branston) { find_or_create :team_branston }
  let(:service) { CurrentTeamAndUserService.new(kase) }

  context "when data to be requested state" do
    let(:kase)  { create :offender_sar_case } # default state

    it "returns the correct team and user" do
      expect(kase.current_state).to eq "data_to_be_requested"
      expect(service.team).to eq team_branston
      expect(service.user).to be_nil
    end
  end

  context "when data to be requested state" do
    let(:kase)  { create :offender_sar_case, :waiting_for_data }

    it "returns the correct team and user" do
      expect(kase.current_state).to eq "waiting_for_data"
      expect(service.team).to eq team_branston
      expect(service.user).to be_nil
    end
  end

  context "when unknown_state" do
    let(:kase)  { create :offender_sar_case }

    it "raises" do
      allow(kase).to receive(:current_state).and_return("of_disbelief")
      expect {
        service
      }.to raise_error(
        RuntimeError,
        "State of_disbelief unrecognised by CurrentTeamAndUser::SAR::Offender",
      )
    end
  end

  context "when offender sar complaint unassigned" do
    let(:kase)  { create :offender_sar_complaint }

    it "returns the correct team and user" do
      expect(kase.current_state).to eq "to_be_assessed"
      expect(service.team).to eq team_branston
      expect(service.user).to be_nil
    end
  end

  context "when offender sar complaint assigned" do
    let(:kase)  { create :accepted_complaint_case }

    it "returns the correct team and user" do
      expect(kase.current_state).to eq "to_be_assessed"
      expect(service.team).to eq team_branston
      expect(service.user).to eq team_branston.users.first
    end
  end
end
