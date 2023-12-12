require "rails_helper"

RSpec.describe ViewsHelper, type: :helper do
  describe "#rejected_offender_sar_case_heading" do
    context "when a case has missing information" do
      let(:kase) { create :rejected_case }

      it "generates a heading on the page" do
        text = helper.get_offender_sar_heading("rejected", kase)
        expected_html = "<span class=\"page-heading--secondary\">Create Rejected Offender SAR case</span>"
        expect(text).to eq(expected_html)
      end
    end
  end
end
