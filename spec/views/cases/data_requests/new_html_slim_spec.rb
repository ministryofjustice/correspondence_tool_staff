require 'rails_helper'

describe 'cases/data_requests/new', type: :view do
  context '#new' do
    let(:offender_sar) { create :offender_sar_case }

    before do
      assign(:data_request, offender_sar.data_requests.new)
      assign(:case, offender_sar)

      render
      data_request_page.load(rendered)
      @page = data_request_page
    end

    it 'has required content' do
      expect(@page.page_heading.heading.text).to eq 'Record data request'
      expect(@page.form).to have_location
      expect(@page.form).to have_request_type
      expect(@page.form.submit_button.value).to eq 'Record request'
    end
  end
end
