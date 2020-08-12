require 'rails_helper'

describe 'cases/data_requests/edit', type: :view do
  context '#edit' do
    let(:data_request) {
      create(
        :data_request,
        location: 'HMP Leicester',
        request_type: 'offender',
        cached_num_pages: 32,
        cached_date_received: Date.new(1972, 9, 25)
      )
    }

    before do
      assign(:data_request, data_request)
      assign(:data_request_log, data_request.new_log)
      assign(:case, data_request.kase)

      render
      data_request_edit_page.load(rendered)
      @page = data_request_edit_page
    end

    it 'has required content' do
      expect(@page.page_heading.heading.text).to eq 'Update page count'
      expect(@page.location.text).to eq 'HMP Leicester'
      expect(@page.request_type.text).to eq 'offender'

      expect(@page.form.date_received_dd.value.to_i).to eq 25
      expect(@page.form.date_received_mm.value.to_i).to eq 9
      expect(@page.form.date_received_yyyy.value.to_i).to eq 1972

      expect(@page.form.num_pages.value.to_i).to eq 32
      expect(@page.submit_button.value).to eq 'Update data received'
    end
  end
end
