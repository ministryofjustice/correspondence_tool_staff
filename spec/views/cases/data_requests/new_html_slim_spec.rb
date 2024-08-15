require "rails_helper"

describe "cases/data_requests/new", type: :view do
  describe "#new" do
    let(:offender_sar) { create :offender_sar_case }
    let(:data_request_area) { create :data_request_area }
    let(:page) { data_request_page }

    before do
      assign(:data_request, data_request_area.data_requests.new)
      assign(:case, offender_sar)
      assign(:data_request_area, offender_sar.data_request_areas)

      render
      data_request_page.load(rendered)
    end

    it "has required content" do
      expect(page.page_heading.heading.text).to eq "Record data request"
      expect(page.form).to have_request_type
      expect(page.form).to have_date_from_day
      expect(page.form).to have_date_from_month
      expect(page.form).to have_date_from_year
      expect(page.form).to have_date_to_day
      expect(page.form).to have_date_to_month
      expect(page.form).to have_date_to_year
      expect(page.form.submit_button.value).to eq "Continue"
    end
  end
end
