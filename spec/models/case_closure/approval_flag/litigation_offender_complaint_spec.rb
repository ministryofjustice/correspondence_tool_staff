require 'rails_helper'

module CaseClosure
  module ApprovalFlag
    RSpec.describe LitigationOffenderComplaint, type: :model do

      it { should validate_presence_of(:name) }
      it { should validate_presence_of(:abbreviation) }
      it { should validate_presence_of(:sequence_id) }

      describe '.id_from_name' do
        it 'returns the id when name exists in the database' do
          complaint_fee_approval = create :offender_litigation_complaint_approval_flag, :fee_approval

          expect(LitigationOffenderComplaint.id_from_name(complaint_fee_approval.name))
            .to eq complaint_fee_approval.id

          expect(LitigationOffenderComplaint.fee_approval).to eq complaint_fee_approval
        end

        it 'returns nil when no record with specified name' do
          expect(LitigationOffenderComplaint.id_from_name('xxxxxxxx')).to be nil
        end
      end
    end
  end
end
