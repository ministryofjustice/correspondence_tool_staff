require 'rails_helper'

module CaseClosure
  RSpec.describe OffenderComplaintApprovalFlag::ICOApprovalFlag, type: :model do

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:abbreviation) }
    it { should validate_presence_of(:sequence_id) }

    describe '.id_from_name' do
      it 'returns the id when name exists in the database' do
        complaint_first_approval = create :offender_ico_complaint_approval_flag, :first_approval
        complaint_second_approval = create :offender_ico_complaint_approval_flag, :second_approval
        complaint_not_approval_required = create :offender_ico_complaint_approval_flag, :not_approval_required

        expect(OffenderComplaintApprovalFlag::ICOApprovalFlag.id_from_name(complaint_first_approval.name))
          .to eq complaint_first_approval.id
        expect(OffenderComplaintApprovalFlag::ICOApprovalFlag.id_from_name(complaint_second_approval.name))
          .to eq complaint_second_approval.id
        expect(OffenderComplaintApprovalFlag::ICOApprovalFlag.id_from_name(complaint_not_approval_required.name))
          .to eq complaint_not_approval_required.id

        expect(OffenderComplaintApprovalFlag::ICOApprovalFlag.first_approval).to eq complaint_first_approval
        expect(OffenderComplaintApprovalFlag::ICOApprovalFlag.second_approval).to eq complaint_second_approval
        expect(OffenderComplaintApprovalFlag::ICOApprovalFlag.not_approval_required).to eq complaint_not_approval_required
      end

      it 'returns nil when no record with specified name' do
        expect(OffenderComplaintApprovalFlag::ICOApprovalFlag.id_from_name('xxxxxxxx')).to be nil
      end
    end
  end

  RSpec.describe OffenderComplaintApprovalFlag::LitigationApprovalFlag, type: :model do

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:abbreviation) }
    it { should validate_presence_of(:sequence_id) }

    describe '.id_from_name' do
      it 'returns the id when name exists in the database' do
        complaint_fee_approval = create :offender_litigation_complaint_approval_flag, :fee_approval

        expect(OffenderComplaintApprovalFlag::LitigationApprovalFlag.id_from_name(complaint_fee_approval.name))
          .to eq complaint_fee_approval.id

        expect(OffenderComplaintApprovalFlag::LitigationApprovalFlag.fee_approval).to eq complaint_fee_approval
      end

      it 'returns nil when no record with specified name' do
        expect(OffenderComplaintApprovalFlag::LitigationApprovalFlag.id_from_name('xxxxxxxx')).to be nil
      end
    end
  end

end
