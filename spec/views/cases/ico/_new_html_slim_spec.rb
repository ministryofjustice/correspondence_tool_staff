require 'rails_helper'

describe 'cases/ico/new.html.slim', type: :view do
  it 'displays the new case page' do
    kase = build(:ico_foi_case)
    assign(:case, kase)
    assign(:correspondence_type, kase.correspondence_type)
    assign(:case_types, ['Case::ICO::FOI', 'Case::ICO::SAR'])
    assign(:s3_direct_post, S3Uploader.s3_direct_post_for_case(kase, :request))

    render _default_file_to_render, { kase: kase }

    cases_new_ico_page.load(rendered)
    # expect(cases_new_ico_page).to have_original_case_type
    expect(cases_new_ico_page).to have_ico_reference_number

    expect(cases_new_ico_page).to have_date_received_day
    expect(cases_new_ico_page).to have_date_received_month
    expect(cases_new_ico_page).to have_date_received_year

    expect(cases_new_ico_page).to have_external_deadline_day
    expect(cases_new_ico_page).to have_external_deadline_month
    expect(cases_new_ico_page).to have_external_deadline_year

    expect(cases_new_ico_page).to have_subject
    expect(cases_new_ico_page).to have_case_details

    expect(cases_new_ico_page).to have_dropzone_container
    expect(cases_new_ico_page.dropzone_container['data-max-filesize-in-mb']).to eq Settings.max_attachment_file_size_in_MB.to_s
  end
end

