require 'rails_helper'

describe CaseExtendForPITDecorator, type: :model do
  subject { CaseExtendForPITDecorator.decorate create(:case) }

  it { should have_attributes extension_deadline_dd: nil }
  it { should have_attributes extension_deadline_mm: nil }
  it { should have_attributes extension_deadline_yyyy: nil }
  it { should have_attributes reason_for_extending: nil }
end
