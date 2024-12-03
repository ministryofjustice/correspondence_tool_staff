require "rails_helper"

describe "cases/data_request_areas/new", type: :view do
  describe "#new" do
    let(:offender_sar) { create :offender_sar_case }
    let(:page) { data_request_area_page }

    before do
      assign(:case, offender_sar)
      assign(:data_request_area, offender_sar.data_request_areas.new)

      render
      data_request_area_page.load(rendered)
    end

    it "has required content" do
      expect(page.page_heading.heading.text).to eq "Record data request"
      expect(page.form).to have_data_request_area_type
      expect(page.form).to have_location
      expect(page.form.submit_button.value).to eq "Continue"
    end
  end
end
