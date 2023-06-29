require "rails_helper"

describe "cases/new.html.slim", type: :view do
  describe "FOIs" do
    it "displays the new case page" do
      kase = Case::FOI::Standard.new.decorate
      assign(:case_types, %w[Standard ComplianceReview TimelinessReview])
      assign(:correspondence_type, "foi")
      assign(:case, kase)
      assign(:s3_direct_post, S3Uploader.s3_direct_post_for_case(kase, :request))
      render

      cases_new_foi_page.load(rendered)

      page = cases_new_foi_page

      expect(page.page_heading.heading.text).to eq "Add case details"
      expect(page.page_heading.sub_heading.text).to eq "Create FOI case "

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
      expect(page.dropzone_container["data-max-filesize-in-mb"]).to eq Settings.max_attachment_file_size_in_MB.to_s

      expect(page).to have_submit_button

      expect(page.submit_button.value).to eq "Create case"
    end
  end

  describe "SARs" do
    it "displays the new case page" do
      kase = Case::SAR::Standard.new.decorate
      assign(:case, kase)
      assign(:s3_direct_post, S3Uploader.s3_direct_post_for_case(kase, :request))

      render

      cases_new_sar_page.load(rendered)

      page = cases_new_sar_page

      expect(page.page_heading.heading.text).to eq "Add case details"
      expect(page.page_heading.sub_heading.text).to eq "Create SAR case "

      expect(page).to have_subject_full_name
      expect(page).to have_third_party
      expect(page).to have_requester_full_name
      expect(page).to have_third_party_relationship
      expect(page).to have_subject_type
      expect(page).to have_date_received_day
      expect(page).to have_date_received_month
      expect(page).to have_date_received_year
      expect(page).to have_request_method

      expect(page).to have_subject
      expect(page).to have_full_request
      expect(page).to have_dropzone_container
      expect(page).to have_reply_method
      expect(page).to have_email
      expect(page).to have_postal_address
      expect(page).to have_flag_for_disclosure_specialists

      expect(page).to have_submit_button

      expect(page.submit_button.value).to eq "Create case"
    end
  end

  describe "ICOs" do
    it "displays the new case page" do
      kase = build(:ico_foi_case).decorate
      assign(:case, kase)
      assign(:correspondence_type, kase.correspondence_type)
      assign(:s3_direct_post, S3Uploader.s3_direct_post_for_case(kase, :request))

      render

      cases_new_ico_page.load(rendered)

      form = cases_new_ico_page.form

      expect(form).to have_ico_officer_name
      expect(form).to have_ico_reference_number
      expect(form).to have_original_case_number
      expect(form).to have_link_original_case
      expect(form).to have_related_case_number
      expect(form).to have_link_related_case

      expect(form).to have_date_received_day
      expect(form).to have_date_received_month
      expect(form).to have_date_received_year

      expect(form).to have_external_deadline_day
      expect(form).to have_external_deadline_month
      expect(form).to have_external_deadline_year

      expect(form).to have_case_details

      expect(form).to have_dropzone_container
      expect(form.dropzone_container["data-max-filesize-in-mb"])
        .to eq Settings.max_attachment_file_size_in_MB.to_s
    end
  end
end
