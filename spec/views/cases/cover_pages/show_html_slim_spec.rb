require "rails_helper"

describe "cases/cover_pages/show", type: :view do
  describe "#show" do
    let(:data_request) do
      create(
        :data_request,
        location: "HMP Leicester",
        request_type: "all_prison_records",
        date_requested: Date.new(2020, 8, 15),
        date_from: Date.new(2018, 8, 15),
        date_to: Date.new(2019, 8, 15),
        cached_num_pages: 32,
        completed: true,
        cached_date_received: Date.new(2020, 8, 15),
      )
    end
    let(:page) { cases_cover_page }

    before do
      assign(:data_request, data_request)
      assign(:case, data_request.kase)

      render
      cases_cover_page.load(rendered)
    end

    it "has required content" do
      expect(page.page_heading.subject_full_name.text).to eq data_request.kase.subject_full_name.to_s
      expect(page.page_heading.case_number.text).to eq data_request.kase.number
      expect(page.page_heading.prison_number.text).to eq data_request.kase.first_prison_number&.upcase
      expect(page.cover_sheet_address.text).to eq data_request.kase.recipient_address

      row = page.data_requests.rows[0]
      expect(row.location).to have_text "HMP Leicester"
      expect(row.request_type).to have_text "All prison records 15 Aug 2018 -  15 Aug 2019"
      expect(row.date_requested).to have_text "15 Aug 2020"
      expect(row.pages.text).to eq "32"
      expect(row.date_received).to have_text "15 Aug 2020"
    end
  end
end
