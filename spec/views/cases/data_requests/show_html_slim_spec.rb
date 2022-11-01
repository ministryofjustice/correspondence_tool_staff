require 'rails_helper'

describe 'cases/data_requests/show', type: :view do
  context '#show' do
    let(:kase) {
      create(
        :offender_sar_case,
        subject_full_name: 'Robert Badson',
      )
    }

    let(:data_request) {
      create(
        :data_request,
        offender_sar_case: kase,
        location: 'HMP Leicester',
        request_type: 'all_prison_records',
        date_requested: Date.new(2022, 10, 21),
        date_from: Date.new(2018, 8, 15),
        cached_num_pages: 32,
        completed: true,
        cached_date_received: Date.new(1972, 9, 25),
      )
    }

    before do
      assign(:data_request, data_request)
      assign(:case, data_request.kase)

      render
      data_request_show_page.load(rendered)
      @page = data_request_show_page
    end

    it 'has required content' do
      expect(@page.page_heading.heading.text).to eq 'View data request'
      expect(@page.data.number.text).to eq "#{kase.number} - Robert Badson"
      expect(@page.data.location.text).to eq 'HMP Leicester'
      expect(@page.data.request_type.text).to eq 'All Prison Records'
      expect(@page.data.date_requested.text).to eq '21 Oct 2022'
      expect(@page.data.date_from.text).to eq '15 Aug 2018'
      expect(@page.data.date_to.text).to eq 'N/A'
      expect(@page.data.pages_received.text).to eq '32'
      expect(@page.data.completed.text).to eq 'Yes'
      expect(@page.link_edit.text).to eq "Edit data request"
      expect(@page.button_select_document.text).to eq "Select Day 1 request document"
    end
  end
end
