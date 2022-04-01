require 'rails_helper'

RSpec.describe RetentionSchedule, type: :model do

  let(:kase) { create(:offender_sar_case) }
  let(:complaint_kase) { create(:offender_sar_complaint) }
  let(:foi_kase) { create(:foi_case) }

  let(:retention_schedule) { 
    RetentionSchedule.new(
      case: kase, 
      planned_erasure_date: Date.today
    ) 
  }

  let(:retention_schedule_for_complaint) { 
    RetentionSchedule.new(
      case: complaint_kase, 
      planned_erasure_date: Date.today
    ) 
  }

  let(:retention_schedule_foi) { 
    RetentionSchedule.new(
      case: foi_kase, 
      planned_erasure_date: Date.today
    ) 
  }

  describe '#status' do
    it 'defaults to "not_set"'do
      expect(retention_schedule.status).to eq('not_set')
    end

    it 'cannot have a status outside of enum definition' do
      expect { 
        retention_schedule.status = 'incorrect_status' 
      }.to raise_error(ArgumentError)
    end
  end

  describe 'validations' do
    it { should belong_to(:case).class_name('Case::SAR::Offender') }
    it { should validate_presence_of(:case) }
    it { should validate_presence_of(:planned_erasure_date) }
    it { should validate_presence_of(:status) }
    
    it 'should be valid' do
      expect(retention_schedule).to be_valid
    end
  end

  describe 'associations' do
    it 'can return associated Offender SAR case' do
      expect(retention_schedule).to be_valid
      expect(retention_schedule.case).to be(kase)
    end

    it 'can return associated Offender SAR Complaint case' do
      expect(retention_schedule_for_complaint).to be_valid
      expect(retention_schedule_for_complaint.case).to be(complaint_kase)
    end

    # remove this test when retention_schedule roled out to all cases
    it 'cannot be associated with an non-offender SAR case' do
      expect { 
        retention_schedule_foi.save 
      }.to raise_error(ActiveRecord::AssociationTypeMismatch)
    end

    it 'kase can return associated case' do
      retention_schedule.save
      expect(kase.retention_schedule).to eq(retention_schedule)
    end
  end
end
