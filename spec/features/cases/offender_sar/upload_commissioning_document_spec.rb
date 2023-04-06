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
end
