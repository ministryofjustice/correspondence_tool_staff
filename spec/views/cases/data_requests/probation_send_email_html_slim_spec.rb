require 'rails_helper'

describe 'cases/data_requests/probation_send_email', type: :view do
  context '#send_email' do
    let(:contact) {
      create(
        :contact,
        data_request_emails: "BranstonRegistryRequests2@justice.gov.uk"
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

    let(:commissioning_document) {
      create(
        :commissioning_document,
        template_name: 'probation',
        updated_at: '2023-04-20 15:27'
      )
    }

    context 'data request with probation template' do
      before do
        assign(:data_request, data_request)
        assign(:case, data_request.kase)
        assign(:commissioning_document, commissioning_document)

        render
        data_request_probation_email_confirmation_page.load(rendered)
        @page = data_request_probation_email_confirmation_page
      end

      it 'has required content' do
        expect(@page.page_heading.heading.text).to eq 'Do you want to send the commissioning email to Branston Archives?'
        # expect(@page.page_banner.text).to include 'The selected location does not have an email address.'
        # expect(@page.button_send_email.disabled?).to eq true
        # expect(@page.link_cancel.text).to eq 'Cancel'
      end
    end

  end
end
