require 'rails_helper'

module CaseClosure
  RSpec.describe OffenderComplaintOutcome, type: :model do

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:abbreviation) }
    it { should validate_presence_of(:sequence_id) }

    describe '.id_from_name' do
      it 'returns the id when name exists in the database' do
        complaint_succeeded = create :offender_complaint_outcome, :succeeded
        complaint_not_succeeded = create :offender_complaint_outcome, :not_succeeded
        complaint_settled = create :offender_complaint_outcome, :settled

        expect(OffenderComplaintOutcome.id_from_name(complaint_succeeded.name))
          .to eq complaint_succeeded.id
        expect(OffenderComplaintOutcome.id_from_name(complaint_not_succeeded.name))
          .to eq complaint_not_succeeded.id
        expect(OffenderComplaintOutcome.id_from_name(complaint_settled.name))
          .to eq complaint_settled.id

        expect(OffenderComplaintOutcome.succeeded).to eq complaint_succeeded
        expect(OffenderComplaintOutcome.not_succeeded).to eq complaint_not_succeeded
        expect(OffenderComplaintOutcome.settled).to eq complaint_settled
      end

      it 'returns nil when no record with specified name' do
        expect(OffenderComplaintOutcome.id_from_name('xxxxxxxx')).to be nil
      end
    end
  end
end
