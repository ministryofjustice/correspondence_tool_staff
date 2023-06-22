require "rails_helper"

describe Case::SAR::OffenderPolicy do
  subject { described_class }

  let(:user) { create :branston_user }

  permissions :can_record_data_request? do
    it { is_expected.to permit(user, create(:offender_sar_case)) }
    it { is_expected.not_to permit(user, create(:sar_case)) }
  end
end
