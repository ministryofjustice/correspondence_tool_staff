require 'rails_helper'

describe 'cases/data_requests/new', type: :view do
  context '#new' do
    let(:offender_sar) { create :offender_sar_case }

    before do
      2.times { offender_sar.data_requests.build }
      assign(:case, offender_sar)

      render
      data_request_page.load(rendered)
      @page = data_request_page
    end

    it 'has required content' do
      expect(@page.page_heading.heading.text).to eq 'Record data request'
      expect(@page.form.location.size).to eq 2
      expect(@page.form.request_type.size).to eq 2
      expect(@page.submit_button.value).to eq 'Record requests'
    end
  end
end
