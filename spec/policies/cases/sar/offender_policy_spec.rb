require 'rails_helper'

describe Case::SAR::OffenderPolicy do
  subject { described_class }
  let(:user) { create :user }

  permissions :can_record_data_request? do
    it { should permit(user, create(:offender_sar_case)) }
    it { should_not permit(user, create(:sar_case)) }
  end
end
