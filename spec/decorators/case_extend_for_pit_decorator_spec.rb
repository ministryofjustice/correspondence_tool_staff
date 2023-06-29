require "rails_helper"

describe CaseExtendForPITDecorator, type: :model do
  subject { described_class.decorate create(:case) }

  it { is_expected.to have_attributes extension_deadline_dd: nil }
  it { is_expected.to have_attributes extension_deadline_mm: nil }
  it { is_expected.to have_attributes extension_deadline_yyyy: nil }
  it { is_expected.to have_attributes reason_for_extending: nil }
end
