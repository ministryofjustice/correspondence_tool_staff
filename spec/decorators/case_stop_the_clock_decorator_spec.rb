require "rails_helper"

describe CaseStopTheClockDecorator, type: :model do
  subject { described_class.decorate create(:case) }

  it { is_expected.to have_attributes stop_the_clock_date_dd: nil }
  it { is_expected.to have_attributes stop_the_clock_date_mm: nil }
  it { is_expected.to have_attributes stop_the_clock_date_yyyy: nil }
  it { is_expected.to have_attributes stop_the_clock_reason: nil }
  it { is_expected.to have_attributes stop_the_clock_categories: nil }
end
