require "rails_helper"

describe CaseExtendSARDeadlineDecorator, type: :model do
  describe "initialize" do
    subject(:sar_extension_decorator) do
      described_class.decorate(create(:sar_case))
    end

    it { is_expected.to have_attributes extension_period: nil }
    it { is_expected.to have_attributes reason_for_extending: nil }
  end

  describe "#allow_extension_period_selection?" do
    let(:new_sar_case)       { create(:sar_being_drafted) }
    let(:extended_sar_case)  { create(:sar_case, :extended_deadline_sar) }

    it "is true for a new SAR" do
      decorated_case = described_class.decorate new_sar_case
      expect(decorated_case.allow_extension_period_selection?).to be true
    end

    it "is false for a SAR that is already extended" do
      decorated_case = described_class.decorate extended_sar_case
      expect(decorated_case.allow_extension_period_selection?).to be false
    end
  end
end
