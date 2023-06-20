require "rails_helper"

feature "downloading a response from response details" do
  given(:manager)   { find_or_create :disclosure_bmt_user }
  given(:responder) { find_or_create :foi_responder }

  given(:response) { build :case_response, user_id: responder.id }
  given(:presigned_url) do
    URI.join(CASE_UPLOADS_S3_BUCKET.url, "#{response.key}&temporary")
  end
  given(:presigned_view_url) do
    URI.join(CASE_UPLOADS_S3_BUCKET.url, "#{response.preview_key}&temporary")
  end

  def stub_s3_response_object(response, url)
    s3_object = instance_double(Aws::S3::Object, presigned_url: url)
    allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                       .with(response.key)
                                       .and_return(s3_object)
  end

  def stub_s3_view_object(response, url)
    s3_object = instance_double(Aws::S3::Object, presigned_url: url)
    allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                       .with(response.preview_key)
                                       .and_return(s3_object)
  end

  background do
    stub_s3_response_object(response, presigned_url)
    stub_s3_view_object(response, presigned_view_url)
  end

  context "when a responder" do
    background do
      login_as responder
    end

    context "with a case being drafted" do
      given(:drafting_case) do
        create :case_with_response,
               responses: [response]
      end

      scenario "when an uploaded response is available" do
        cases_show_page.load(id: drafting_case.id)

        expect(cases_show_page.case_attachments.first.collection.first.actions).to have_view

        expect {
          cases_show_page.case_attachments.first.collection.first.actions.download.click
        }.to redirect_to_external(presigned_url)
      end

      scenario "when a view link is available" do
        mypath = File.join(Rails.root, "spec", "fixtures", "eon.pdf")
        s3_object = instance_double(Aws::S3::Object)
        expect(CASE_UPLOADS_S3_BUCKET).to receive(:object).and_return(s3_object)
        expect(Tempfile).to receive(:new).and_return(double(Tempfile, path: mypath, close: nil))
        expect(s3_object).to receive(:get).with(response_target: mypath)
        expect_any_instance_of(Cases::AttachmentsController).to receive(:send_file)
          .with(mypath, { type: "application/pdf", disposition: "inline" })
          .and_call_original

        cases_show_page.load(id: drafting_case.id)
        cases_show_page.case_attachments.first.collection.first.actions.view.click
      end
    end
  end

  context "when an manager" do
    background do
      login_as manager
    end

    context "with a case marked as sent" do
      given(:sent_case) do
        create :responded_case,
               manager:,
               responder:,
               responses: [response]
      end

      scenario "when an uploaded response is available" do
        cases_show_page.load(id: sent_case.id)

        expect {
          cases_show_page.case_attachments.first.collection.first.actions.download.click
        }.to redirect_to_external(presigned_url)
      end
    end
  end
end
