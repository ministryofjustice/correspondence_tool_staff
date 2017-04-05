require 'rails_helper'

feature 'downloading a response from response details' do
  given(:manager)   { create :manager }
  given(:responder) { create :responder  }

  given(:response) { build :case_response }
  given(:presigned_url) do
    URI.encode("#{CASE_UPLOADS_S3_BUCKET.url}/#{response.key}&temporary")
  end

  def stub_s3_response_object(response, url)
    s3_object = instance_double(Aws::S3::Object, presigned_url: url)
    allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                       .with(response.key)
                                       .and_return(s3_object)
  end

  background do
    stub_s3_response_object(response, presigned_url)
  end

  context 'as a responder' do
    background do
      login_as responder
    end

    context 'with a case being drafted' do
      given(:drafting_case) do
        create :case_with_response,
               manager: manager,
               responder: responder,
               responses: [response]
      end

      scenario 'when an uploaded response is available' do
        cases_show_page.load(id: drafting_case.id)

        expect(cases_show_page.response_details.responses.first).to have_view

        expect {
          cases_show_page.response_details.responses.first.download.click
        }.to redirect_to_external(presigned_url)
      end
    end
  end

  context 'as an manager' do
    background do
      login_as manager
    end

    context 'with a case marked as sent' do
      given(:sent_case) do
        create :responded_case,
               manager: manager,
               responder: responder,
               responses: [response]
      end

      scenario 'when an uploaded response is available' do
        cases_show_page.load(id: sent_case.id)

        expect {
          cases_show_page.response_details.responses.first.download.click
        }.to redirect_to_external(presigned_url)
      end
    end
  end
end
