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

  describe "#formatted_data_request_area_type" do
    it "returns 'prison' for 'prison' data_request_area_type" do
      expect(formatted_data_request_area_type('prison')).to eq('prison')
    end

    it "returns 'Branston' for 'branston' data_request_area_type" do
      expect(formatted_data_request_area_type('branston')).to eq('Branston')
    end

    it "returns 'Branston registry' for 'branston_registry' data_request_area_type" do
      expect(formatted_data_request_area_type('branston_registry')).to eq('Branston Registry')
    end

    it "returns 'MAPPA' for 'mappa' data_request_area_type" do
      expect(formatted_data_request_area_type('mappa')).to eq('MAPPA')
    end

    it "returns 'probation' for 'probation' data_request_area_type" do
      expect(formatted_data_request_area_type('probation')).to eq('probation')
    end
  end
end
