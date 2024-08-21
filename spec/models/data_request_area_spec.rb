# == Schema Information
#
# Table name: data_request_areas
#
#  id                     :bigint           not null, primary key
#  case_id                :bigint           not null
#  user_id                :bigint           not null
#  contact_id             :bigint
#  data_request_area_type :enum             not null
#  location               :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
require "rails_helper"

RSpec.describe DataRequestArea, type: :model do
  describe "#create" do
    context "with valid params" do
      subject(:data_request_area) do
        described_class.new(
          offender_sar_case: build(:offender_sar_case),
          user: build_stubbed(:user),
          data_request_area_type: "prison",
          location: "X" * 500, # Max length
        )
      end

      it { is_expected.to be_valid }

      it "defaults to not started" do
        expect(data_request_area.status).to eq "Not started"
      end
    end
  end

  describe "validation" do
    subject(:data_request_area) { build(:data_request_area) }

    it { is_expected.to be_valid }

    it "requires data request area type" do
      data_request_area.data_request_area_type = nil
      expect(data_request_area).not_to be_valid
    end

    it "requires a creating user" do
      data_request_area.user = nil
      expect(data_request_area).not_to be_valid
    end

    it "requires a case" do
      data_request_area.offender_sar_case = nil
      expect(data_request_area).not_to be_valid
    end
  end

  describe "#data_request_area_type" do
    context "with valid values" do
      it "does not error" do
        expect(build_stubbed(:data_request_area, data_request_area_type: "prison")).to be_valid
        expect(build_stubbed(:data_request_area, data_request_area_type: "probation")).to be_valid
        expect(build_stubbed(:data_request_area, data_request_area_type: "branston")).to be_valid
        expect(build_stubbed(:data_request_area, data_request_area_type: "branston_registry")).to be_valid
        expect(build_stubbed(:data_request_area, data_request_area_type: "mappa")).to be_valid
      end
    end

    context "with invalid value" do
      it "raises an error" do
        expect {
          build_stubbed(:data_request_area, data_request_area_type: "user")
        }.to raise_error ArgumentError
      end
    end

    context "when nil" do
      it "is invalid and returns an error message" do
        data_request_area = build_stubbed(:data_request_area, data_request_area_type: nil)
        expect(data_request_area).not_to be_valid
        expect(data_request_area.errors[:data_request_area_type]).to eq ["Select where the data you are requesting is from"]
      end
    end
  end

  describe "#status" do
    context "when data request area has no data request items" do
      let(:data_request_area) { build(:data_request_area) }

      it "returns 'Not started'" do
        expect(data_request_area.status).to eq "Not started"
      end
    end

    context "when data request area has unfinished data request items" do
      let(:data_request_area) { create(:data_request_area) }
      let!(:data_request) { create(:data_request, completed: false, data_request_area:) }

      it "returns 'In progress'" do
        expect(data_request_area.status).to eq "In progress"
      end
    end

    context "when data request is completed" do
      let(:data_request_area) { create(:data_request_area) }
      let!(:data_request) { create(:data_request, :completed, cached_date_received: Date.new(2024, 8, 13), data_request_area:) }

      it "returns 'Completed'" do
        expect(data_request_area.status).to eq "Completed"
      end
    end
  end

  describe "#clean_attributes" do
    subject(:data_request_area) { build :data_request_area }

    it "ensures string attributes do not have leading/trailing spaces" do
      data_request_area.location = "  The location"
      data_request_area.send(:clean_attributes)
      expect(data_request_area.location).to eq "The location"
    end

    it "ensures string attributes have the first letter capitalised" do
      data_request_area.location = "leicester"
      data_request_area.send(:clean_attributes)
      expect(data_request_area.location).to eq "Leicester"
    end
  end

  describe "scopes" do
    let(:data_request_area_in_progress) do
      data_request_area = create(:data_request_area)
      create(:data_request, completed: false, data_request_area:)
      data_request_area
    end

    let(:data_request_area_completed) do
      data_request_area = create(:data_request_area)
      create(:data_request, completed: true, cached_date_received: Date.new(2024, 8, 13), data_request_area:)
      data_request_area
    end

    let(:data_request_area_not_started) { create(:data_request_area) }

    describe "scope completed" do
      it "returns data request areas with completed data requests" do
        expect(described_class.completed).to include(data_request_area_completed)
        expect(described_class.completed).not_to include(data_request_area_not_started)
        expect(described_class.completed).not_to include(data_request_area_in_progress)
      end
    end

    describe "scope in_progress" do
      it "returns data request areas with in-progress (unfinished) data requests" do
        expect(described_class.in_progress).to include(data_request_area_in_progress)
        expect(described_class.in_progress).not_to include(data_request_area_not_started)
        expect(described_class.in_progress).not_to include(data_request_area_completed)
      end
    end

    describe "scope not_started" do
      it "returns data request areas with no data requests" do
        expect(described_class.not_started).to include(data_request_area_not_started)
        expect(described_class.not_started).not_to include(data_request_area_in_progress)
        expect(described_class.not_started).not_to include(data_request_area_completed)
      end
    end
  end
end
