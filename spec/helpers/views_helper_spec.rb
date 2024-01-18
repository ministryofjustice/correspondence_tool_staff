require "rails_helper"

describe "Creating an offender sar" do
  context "adding a rejected offender sar case" do
    it "should display the title for a rejected offender sar" do
      @kase = described_class.new
      expect(get_headings(kase, "cases.new.offender_sar.rejected").to eq("Create a rejected offender sar"))
    end
  end
end
