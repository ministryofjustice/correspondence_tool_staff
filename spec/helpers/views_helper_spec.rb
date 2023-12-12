require "rails_helper"

RSpec.describe ViewsHelper, type: :helper do
  describe "#rejected offender sar case" do
    context "when responder enters a case with missing info" do
      let(:responder)    { find_or_create :sar_responder }
      let(:team)         { find_or_create :sar_responding_team }
      let(:kase)         { create :rejected_case }

      it "generates a heading on the page" do
        expect(text).to eq(
          "<span class=\"page-heading--secondary\">Rejected Offender Sar</span>",
        )
      end
    end
  end
end
