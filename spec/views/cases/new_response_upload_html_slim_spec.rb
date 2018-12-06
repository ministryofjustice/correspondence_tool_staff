require 'rails_helper'

describe 'cases/new_response_upload.html.slim', type: :view do

  let(:drafting_case)         { build_stubbed(:accepted_case, :taken_on_by_press).decorate }
  let(:pending_clearance_case){ build_stubbed(:approved_ico_foi_case).decorate }

  context 'upload-redraft' do
    it 'displays the uploader' do
      assign(:case, drafting_case)
      assign(:s3_direct_post, S3Uploader.s3_direct_post_for_case(drafting_case, :response))
      params[:mode] = 'upload-redraft'
      render

      cases_new_response_upload_page.load(rendered)

      puts cases_new_response_upload_page.load(rendered)

      page = cases_new_response_upload_page

      expect(page.page_heading.heading.text).to eq "Upload response"
      expect(page).to have_draft_compliant
    end
  end

  context 'upload' do
    it 'displays the uploader' do
      assign(:case, drafting_case)
      assign(:s3_direct_post, S3Uploader.s3_direct_post_for_case(drafting_case, :response))
      params[:mode] = 'upload'
      render

      cases_new_response_upload_page.load(rendered)

      puts cases_new_response_upload_page.load(rendered)

      page = cases_new_response_upload_page

      expect(page.page_heading.heading.text).to eq "Upload response"
      expect(page).not_to have_draft_compliant
    end
  end
end
