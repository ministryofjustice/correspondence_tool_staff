require 'rails_helper'

describe CaseExtendSARDeadlineDecorator, type: :model do
  context 'initialize' do
    subject(:sar_extension_decorator) {
      CaseExtendSARDeadlineDecorator.decorate(create(:sar_case))
    }

    it { should have_attributes extension_period: nil }
    it { should have_attributes reason_for_extending: nil }
  end

  context '#allow_extension_period_selection?' do
    let(:new_sar_case)       { create(:sar_being_drafted) }
    let(:extended_sar_case)  { create(:extended_deadline_sar) }

    it 'should be true for a new SAR' do
      decorated_case = CaseExtendSARDeadlineDecorator.decorate new_sar_case
      expect(decorated_case.allow_extension_period_selection?).to be true
    end

    it 'should be false for a SAR that is already extended' do
      decorated_case = CaseExtendSARDeadlineDecorator.decorate extended_sar_case
      expect(decorated_case.allow_extension_period_selection?).to be false
    end
  end
end
