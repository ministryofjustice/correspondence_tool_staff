require "rails_helper"

module CaseClosure
  RSpec.describe OffenderComplaintOutcome, type: :model do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:abbreviation) }
    it { is_expected.to validate_presence_of(:sequence_id) }

    describe ".id_from_name" do
      it "returns the id when name exists in the database" do
        complaint_succeeded = create :offender_complaint_outcome, :succeeded
        complaint_not_succeeded = create :offender_complaint_outcome, :not_succeeded
        complaint_settled = create :offender_complaint_outcome, :settled

        expect(described_class.id_from_name(complaint_succeeded.name))
          .to eq complaint_succeeded.id
        expect(described_class.id_from_name(complaint_not_succeeded.name))
          .to eq complaint_not_succeeded.id
        expect(described_class.id_from_name(complaint_settled.name))
          .to eq complaint_settled.id

        expect(described_class.succeeded).to eq complaint_succeeded
        expect(described_class.not_succeeded).to eq complaint_not_succeeded
        expect(described_class.settled).to eq complaint_settled
      end

      it "returns nil when no record with specified name" do
        expect(described_class.id_from_name("xxxxxxxx")).to be nil
      end
    end
  end
end
