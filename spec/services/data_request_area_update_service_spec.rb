require "rails_helper"

describe DataRequestAreaUpdateService do
  let(:user) { create :user }
  let(:offender_sar_case) { create :offender_sar_case }
  let(:data_request_area) { create :data_request_area, location: "HMP Brixton" }
  let(:params) { { data_request_area_type: "prison" } }
  let(:service) do
    described_class.new(
      user:,
      data_request_area:,
      params:,
    )
  end

  describe "#initialize" do
    it "requires a user. data request area and fields to update" do
      expect(service.instance_variable_get(:@user)).to eq user
      expect(service.data_request_area).to eq data_request_area
      expect(service.instance_variable_get(:@params)).to eq params
    end
  end

  describe "#call" do
    context "when location is updated successfully" do
      let(:params) { { location: "New Location" } }

      it "updates the data_request_area location and sets result to :ok" do
        service.call

        expect(data_request_area.reload.location).to eq("New Location")
        expect(service.result).to eq(:ok)
      end
    end

    context "when no changes are made" do
      let(:params) { { location: data_request_area.location } }

      it "does not update the data_request_area and sets result to :unprocessed" do
        service.call

        expect(data_request_area.reload.location).to eq("HMP Brixton")
      end
    end
  end
end
