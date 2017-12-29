require 'rails_helper'

describe 'cases/new.html.slim', type: :view do

  context 'FOIs' do
    it 'displays the new case page' do
      kase = Case::FOI::Standard.new
      assign(:case, kase)
      assign(:s3_direct_post, S3Uploader.s3_direct_post_for_case(kase, :request))
      render

      cases_new_page.load(rendered)

      page = cases_new_page

      expect(page.page_heading.heading.text).to eq "Add case details"
      expect(page.page_heading.sub_heading.text).to eq "Create case "

      expect(page).to have_date_received_day
      expect(page).to have_date_received_month
      expect(page).to have_date_received_year

      expect(page).to have_subject
      expect(page).to have_full_request
      expect(page).to have_full_name
      expect(page).to have_email
      expect(page).to have_address
      expect(page).to have_type_of_requester
      expect(page).to have_case_type
      expect(page).to have_flag_for_disclosure_specialists

      expect(page).to have_submit_button

      expect(page.submit_button.value).to eq "Next - Assign case"

    end
  end

  context 'SARs' do
    it 'displays the new case page' do
      kase = Case::SAR.new
      assign(:case, kase)
      assign(:s3_direct_post, S3Uploader.s3_direct_post_for_case(kase, :request))

      render

      cases_new_page.load(rendered)

      page = cases_new_page

      expect(page.page_heading.heading.text).to eq "Add case details"
      expect(page.page_heading.sub_heading.text).to eq "Create case "

      expect(page).to have_date_received_day
      expect(page).to have_date_received_month
      expect(page).to have_date_received_year

      expect(page).to have_subject
      expect(page).to have_full_request
      expect(page).to have_full_name
      expect(page).to have_email
      expect(page).to have_address
      expect(page).to have_type_of_requester
      expect(page).to have_case_type
      expect(page).to have_flag_for_disclosure_specialists

      expect(page).to have_submit_button

      expect(page.submit_button.value).to eq "Next - Assign case"
    end
  end
end
