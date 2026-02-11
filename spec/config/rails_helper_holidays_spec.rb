require "rails_helper"

RSpec.describe "Rails helper bank holidays setup" do
  it "maps ew_bank_holidays strings to Date objects and assigns them to BusinessTime::Config.holidays" do
    # rails_helper defines/stubs BusinessTime::Config and assigns holidays in a before block
    holidays = BusinessTime::Config.holidays

    expect(holidays).to be_an(Array)
    expect(holidays).not_to be_empty
    expect(holidays).to all(be_a(Date))

    # Spot-check a value we know is present in the ew_bank_holidays list
    expect(holidays).to include(Date.parse("2026-12-25"))
  end
end
