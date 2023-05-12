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

    let(:commissioning_document) {
      create(
        :commissioning_document,
        data_request: data_request,
      )
    }

    context 'data request with contact without email address' do
      let(:contact) {
        create(
          :contact,
          data_request_emails: nil
        )
      }
      before do
        assign(:data_request, data_request)
        assign(:case, data_request.kase)
        assign(:commissioning_document, commissioning_document)

        render
        data_request_email_confirmation_page.load(rendered)
        @page = data_request_email_confirmation_page
      end

      it 'has required content' do
        expect(@page.page_heading.heading.text).to eq 'Are you sure you want to send the commissioning email?'
        expect(@page.page_banner.text).to include 'The selected location does not have an email address.'
        expect(@page.button_send_email.disabled?).to eq true
        expect(@page.link_cancel.text).to eq 'Cancel'
      end
    end

    context 'data request with contact which has email address' do
      before do
        assign(:data_request, data_request)
        assign(:case, data_request.kase)
        assign(:commissioning_document, commissioning_document)

        render
        data_request_email_confirmation_page.load(rendered)
        @page = data_request_email_confirmation_page
      end

      it 'has required content' do
        expect(@page.page_heading.heading.text).to eq 'Are you sure you want to send the commissioning email?'
        expect(@page.button_send_email.value).to eq 'Send commissioning email'
        expect(@page.link_cancel.text).to eq 'Cancel'
      end
    end

    context 'data request with several contact email addresses, each separated by multiple spaces and carriage returns which are removed.' do
        let(:contact) {
          create(
            :contact,
            data_request_emails: "oscar@grouch.com\s\s\s\n\s\sbig@bird.com\n\ncookie@monster.com\s\n\nmr@snuffleupagus.com\n"
          )
        }
        before do
          assign(:data_request, data_request)
          assign(:case, data_request.kase)
          assign(:commissioning_document, commissioning_document)
  
          render
          data_request_email_confirmation_page.load(rendered)
          @page = data_request_email_confirmation_page
        end
  
        it 'has required content' do
          expect(@page.page_heading.heading.text).to eq 'Are you sure you want to send the commissioning email?'
          expect(@page).to have_text 'oscar@grouch.combig@bird.comcookie@monster.commr@snuffleupagus.com'
          expect(@page.button_send_email.value).to eq 'Send commissioning email'
          expect(@page.link_cancel.text).to eq 'Cancel'
        end
      end
  end
end
