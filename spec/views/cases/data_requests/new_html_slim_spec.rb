require 'rails_helper'

describe 'cases/data_requests/new', type: :view do
  context '#new' do
    let(:offender_sar) { create :offender_sar_case }
    let(:data_request) {
      DataRequest.new(location: 'A Place', data: 'Some data')
    }

    before do
      assign(:data_request, data_request)
      assign(:case, offender_sar)

      render
      data_request_page.load(rendered)
      @page = data_request_page
    end

    it 'has required content' do
      expect(@page.page_heading.heading.text).to eq 'Record data request'
      expect(@page.location.value).to eq 'A Place'
      expect(@page.data.value).to eq 'Some data'
      expect(@page.submit_button.value).to eq 'Record requests'
    end
  end
end
