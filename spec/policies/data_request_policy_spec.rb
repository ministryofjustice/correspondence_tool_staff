require 'rails_helper'

describe DataRequestPolicy do
  let(:branston_user) { create :branston_user }
  let(:offender_sar_case) { create :offender_sar_case }
  let(:foi_case) { create :foi_case }

  subject { described_class }

  permissions :new? do
    it { should     permit(branston_user, offender_sar_case)  }
    it { should_not permit(branston_user, foi_case) }
  end

  permissions :create? do
    it { should     permit(branston_user, offender_sar_case)  }
    it { should_not permit(branston_user, foi_case) }
  end
end
