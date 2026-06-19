require "rails_helper"

describe CaseRemoveSARDeadlineExtensionDecorator, type: :model do
  describe "initialize" do
    subject(:remove_extension_decorator) do
      described_class.decorate(create(:sar_case, :extended_deadline_sar))
    end

    it { is_expected.to have_attributes reason_for_removing_extension: nil }
  end

  describe "#removal_makes_case_late?" do
    it "is false when the reverted deadline is not in the past" do
      freeze_time do
        kase = create(:sar_case, :extended_deadline_sar)

        expect(described_class.decorate(kase).removal_makes_case_late?).to be false
      end
    end

    it "is true when the reverted deadline is in the past" do
      freeze_time do
        kase = create(:sar_case, :extended_deadline_sar, received_date: Date.new(2022, 6, 1))

        expect(described_class.decorate(kase).removal_makes_case_late?).to be true
      end
    end
  end
end
