require 'rails_helper'

describe 'cases/cover_pages/show', type: :view do
  context '#show' do
    let(:data_request) {
      create(
        :data_request,
        location: 'HMP Leicester',
        request_type: 'all_prison_records',
        date_requested: Date.new(2020, 8, 15),
        date_from: Date.new(2018, 8, 15),
        date_to: Date.new(2019, 8, 15),
        cached_num_pages: 32,
        cached_date_received: Date.new(2020, 8, 15),
      )
    }

    before do
      assign(:data_request, data_request)
      assign(:case, data_request.kase)

      render
      cases_cover_page.load(rendered)
      @page = cases_cover_page
    end

    it 'has required content' do
      expect(@page.page_heading.heading.text).to eq "#{data_request.kase.subject_full_name&.upcase}-#{data_request.kase.prison_number}"

      row = @page.data_requests.rows[0]
      expect(row.location).to have_text 'HMP Leicester'
      expect(row.request_type).to have_text 'All prison records 15 Aug 2018 -  15 Aug 2019'
      expect(row.date_requested).to have_text '15 Aug 2020'
      expect(row.pages.text).to eq ''
      expect(row.date_received).to have_text '15 Aug 2020'
    end
  end
end
