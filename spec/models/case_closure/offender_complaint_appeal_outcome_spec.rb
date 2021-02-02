require 'rails_helper'

module CaseClosure
  RSpec.describe OffenderComplaintAppealOutcome, type: :model do

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:abbreviation) }
    it { should validate_presence_of(:sequence_id) }

    describe '.id_from_name' do
      it 'returns the id when name exists in the database' do
        complaint_upheld = create :offender_complaint_appeal_outcome, :upheld
        complaint_not_upheld = create :offender_complaint_appeal_outcome, :not_upheld
        complaint_not_response_received= create :offender_complaint_appeal_outcome, :not_response_received

        expect(OffenderComplaintAppealOutcome.id_from_name(complaint_upheld.name))
          .to eq complaint_upheld.id
        expect(OffenderComplaintAppealOutcome.id_from_name(complaint_not_upheld.name))
          .to eq complaint_not_upheld.id
        expect(OffenderComplaintAppealOutcome.id_from_name(complaint_not_response_received.name))
          .to eq complaint_not_response_received.id

        expect(OffenderComplaintAppealOutcome.upheld).to eq complaint_upheld
        expect(OffenderComplaintAppealOutcome.not_upheld).to eq complaint_not_upheld
        expect(OffenderComplaintAppealOutcome.not_response_received).to eq complaint_not_response_received
      end

      it 'returns nil when no record with specified name' do
        expect(OffenderComplaintAppealOutcome.id_from_name('xxxxxxxx')).to be nil
      end
    end
  end
end
