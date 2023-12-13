require "rails_helper"

RSpec.describe ViewsHelper, type: :helper do
  describe "#rejected_offender_sar_case_heading" do
    context "when a case has missing information" do
      let(:kase) { create :rejected_case }

      it "generates a heading" do
        text = helper.get_offender_sar_heading("rejected", kase)
        expected_heading = "Create Rejected Offender SAR case"
        expect(text).to include(expected_heading)
      end
    end
  end
end
