require "rails_helper"

RSpec.configure do |config|
  config.include AbstractController::Translation
end

describe ViewsHelper, type: :helper do
  include CasesHelper

  describe "#get_sub_heading" do
    let(:key_path) { "cases.new" }

    it "returns text for rejected case type heading" do
      test_case = build(:offender_sar_case, :rejected)
      page_title = get_sub_heading(test_case, key_path)
      expect(page_title).to eq("Create rejected Offender SAR case")
    end

    it "returns text for sub_heading" do
      test_case = build(:offender_sar_case)
      page_title = get_sub_heading(test_case, key_path)
      expect(page_title).to eq("Create Offender SAR case")
    end
  end
end
