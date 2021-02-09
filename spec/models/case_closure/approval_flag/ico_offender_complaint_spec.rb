require 'rails_helper'

module CaseClosure
  module ApprovalFlag
    RSpec.describe ICOOffenderComplaint, type: :model do

      it { should validate_presence_of(:name) }
      it { should validate_presence_of(:abbreviation) }
      it { should validate_presence_of(:sequence_id) }

      describe '.id_from_name' do
        it 'returns the id when name exists in the database' do
          complaint_first_approval = create :offender_ico_complaint_approval_flag, :first_approval
          complaint_second_approval = create :offender_ico_complaint_approval_flag, :second_approval
          complaint_no_approval_required = create :offender_ico_complaint_approval_flag, :no_approval_required

          expect(ICOOffenderComplaint.id_from_name(complaint_first_approval.name))
            .to eq complaint_first_approval.id
          expect(ICOOffenderComplaint.id_from_name(complaint_second_approval.name))
            .to eq complaint_second_approval.id
          expect(ICOOffenderComplaint.id_from_name(complaint_no_approval_required.name))
            .to eq complaint_no_approval_required.id

          expect(ICOOffenderComplaint.first_approval).to eq complaint_first_approval
          expect(ICOOffenderComplaint.second_approval).to eq complaint_second_approval
          expect(ICOOffenderComplaint.no_approval_required).to eq complaint_no_approval_required
        end

        it 'returns nil when no record with specified name' do
          expect(ICOOffenderComplaint.id_from_name('xxxxxxxx')).to be nil
        end
      end
    end
    
  end
end
