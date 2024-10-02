require "rails_helper"

describe "cases/data_requests/edit", type: :view do
  describe "#edit" do
    let(:data_request) do
      create(
        :data_request,
        request_type: "all_prison_records",
        date_from: Date.new(2018, 8, 15),
        date_to: Date.new(2019, 8, 15),
        cached_num_pages: 32,
        completed: true,
        cached_date_received: Date.new(1972, 9, 25),
      )
    end
    let(:page) { data_request_edit_page }
    let(:data_request_area) { create :data_request_area }

    before do
      assign(:data_request, data_request)
      assign(:data_request_area, data_request_area)
      assign(:case, data_request_area.kase)

      render
      data_request_edit_page.load(rendered)
    end

    it "has required content" do
      expect(page.page_heading.heading.text).to eq "Edit data request"
      expect(page.form.date_from_day.value.to_i).to eq 15
      expect(page.form.date_from_month.value.to_i).to eq 8
      expect(page.form.date_from_year.value.to_i).to eq 2018
      expect(page.form.date_to_day.value.to_i).to eq 15
      expect(page.form.date_to_month.value.to_i).to eq 8
      expect(page.form.date_to_year.value.to_i).to eq 2019
      expect(page.form.cached_num_pages.value.to_i).to eq 32
      expect(page.submit_button.value).to eq "Continue"
    end
  end
end
