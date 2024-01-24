require "rails_helper"

RSpec.configure do |config|
  config.include AbstractController::Translation
  end

describe ViewsHelper, type: :helper do

  include CasesHelper

    describe "#get_headings" do
      it "text for rejected case type heading" do

        test_kase = build(:offender_sar_case, :rejected)

        test_correspondence_type = build(:offender_sar_correspondence_type)

        view_title = get_headings(test_kase, test_correspondence_type)

        expect(view_title).to eq("Create Rejected Offender SAR case")
      end
    end

    describe "#get_headings" do

      it "#text for a sub_heading" do

        test_kase = build(:offender_sar_case)

        test_correspondence_type = build(:offender_sar_correspondence_type)

        view_title = get_headings(test_kase, test_correspondence_type)

        expect(view_title).to eq("Create Offender SAR case")
      end
    end
end
