require 'rails_helper'

feature 'Upload commissioning document' do
  given(:manager) { find_or_create :branston_user }
  given(:offender_sar_case) { create(:offender_sar_case).decorate }
  given(:data_request) { create(:data_request, offender_sar_case: offender_sar_case) }
  given!(:commissioning_document) { create(:commissioning_document, data_request: data_request) }

  background do
    login_as manager
  end

  scenario 'clicking replace link on data request page goes to upload page' do
    data_request_show_page.load(case_id: offender_sar_case.id, id: data_request.id)
    click_on 'Replace'

    expect(upload_commissioning_document_page).to be_displayed
  end

  scenario 'upload a docx file', js: true do
    data_request_show_page.load(case_id: offender_sar_case.id, id: data_request.id)
    click_on 'Replace'
    expect(upload_commissioning_document_page).to be_displayed

    upload_file = Rails.root.join('spec', 'fixtures', 'response.docx')
    upload_commissioning_document_page.drop_in_dropzone(upload_file)
    upload_commissioning_document_page.upload_document_button.click
    expect(data_request_show_page).to be_displayed
    expect(data_request_show_page).to have_content(I18n.t("notices.commissioning_document_uploaded"))
    last_file = offender_sar_case.attachments.last
    expect(last_file.key).to match %{/response.docx$}
  end

  scenario 'upload a different filetype', js: true do
    data_request_show_page.load(case_id: offender_sar_case.id, id: data_request.id)
    click_on 'Replace'
    expect(upload_commissioning_document_page).to be_displayed

    upload_file = Rails.root.join('spec', 'fixtures', 'new request.pdf')
    upload_commissioning_document_page.drop_in_dropzone(upload_file)
    expect(upload_commissioning_document_page).to have_content("You can't upload files of this type.")
  end
end
