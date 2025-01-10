require "rails_helper"

describe Case::SAR::OffenderPolicy do
  subject { described_class }

  let(:user) { create :branston_user }

  describe "user permissions" do
    it "checks can record data requests" do
      permissions :can_record_data_request? do
        it { is_expected.to permit(user, create(:offender_sar_case)) }
        it { is_expected.not_to permit(user, create(:sar_case)) }
      end
    end
  end

  describe "actions permitted" do
    it "checks can send day 1 email" do
      permissions :can_send_day_1_email? do
        it { is_expected.to permit(user, create(:offender_sar_case)) }
        it { is_expected.not_to permit(user, create(:offender_sar_complaint)) }
      end
    end
  end
end
