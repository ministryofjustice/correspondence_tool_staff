require "rails_helper"

module CaseClosure
  RSpec.describe OffenderComplaintAppealOutcome, type: :model do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:abbreviation) }
    it { is_expected.to validate_presence_of(:sequence_id) }

    describe ".id_from_name" do
      it "returns the id when name exists in the database" do
        complaint_upheld = create :offender_complaint_appeal_outcome, :upheld
        complaint_not_upheld = create :offender_complaint_appeal_outcome, :not_upheld
        complaint_not_response_received = create :offender_complaint_appeal_outcome, :not_response_received

        expect(described_class.id_from_name(complaint_upheld.name))
          .to eq complaint_upheld.id
        expect(described_class.id_from_name(complaint_not_upheld.name))
          .to eq complaint_not_upheld.id
        expect(described_class.id_from_name(complaint_not_response_received.name))
          .to eq complaint_not_response_received.id

        expect(described_class.upheld).to eq complaint_upheld
        expect(described_class.not_upheld).to eq complaint_not_upheld
        expect(described_class.not_response_received).to eq complaint_not_response_received
      end

      it "returns nil when no record with specified name" do
        expect(described_class.id_from_name("xxxxxxxx")).to be nil
      end
    end
  end
end
