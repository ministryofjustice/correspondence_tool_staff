require 'rails_helper'

describe 'cases/data_requests/send_email', type: :view do
  context '#send_email' do

    it 'has required content' do
      expect(@page.page_heading.heading.text).to eq 'Are you sure you want to send the commissioning email?'
      expect(@page.submit_button.value).to eq 'Send Commissioning Email'
    end
  end
end
