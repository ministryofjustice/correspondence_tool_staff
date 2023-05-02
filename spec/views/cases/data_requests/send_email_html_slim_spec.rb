require 'rails_helper'

describe 'cases/data_requests/send_email', type: :view do
  context '#send_email' do
    let(:contact) {
      create(
        :contact,
        data_request_emails: "oscar@grouch.com\nbig@bird.com"
      )
    }

    let(:kase) {
      create(
        :offender_sar_case,
        subject_full_name: 'Minnie Mouse',
      )
    }

    let(:data_request) {
      create(
        :data_request,
        offender_sar_case: kase,
        contact: contact
      )
    }

    context 'data request with contact which has email address' do
      before do
        assign(:data_request, data_request)
        assign(:case, data_request.kase)

        render
        data_request_email_confirmation_page.load(rendered)
        @page = data_request_email_confirmation_page
      end

      it 'has required content' do
        expect(@page.page_heading.heading.text).to eq 'Are you sure you want to send the commissioning email?'
        expect(@page.button_send_email.text).to eq 'Send commissioning email'
        expect(@page.link_cancel.text).to eq 'Cancel'
      end
    end
  end
end
