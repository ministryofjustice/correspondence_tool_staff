require 'rails_helper'

feature 'Generate a commissioning document for a data request' do
  given(:manager) { find_or_create :branston_user }
  given(:offender_sar_case) { create(:offender_sar_case, :waiting_for_data, received_date: 1.business_day.ago).decorate }

  background do
    create(:data_request, offender_sar_case: offender_sar_case)
    login_as manager
  end

  scenario 'successfully select a template and download a file' do
    cases_show_page.load(id: offender_sar_case.id)
    data_requests = cases_show_page.data_requests.rows
    expect(data_requests.size).to eq 1
    click_on 'View'

    expect(data_request_show_page).to be_displayed
    click_on 'Select Day 1 request document'

    expect(commissioning_document_page).to be_displayed
    commissioning_document_page.form.choose_template_name('prison')
    click_on 'Download Day 1 request document'
    expect(page.response_headers['Content-Disposition']).to match(/filename=\".*docx\"/)
  end

  scenario 'attempts to download without selecting a template type' do
    cases_show_page.load(id: offender_sar_case.id)
    data_requests = cases_show_page.data_requests.rows
    expect(data_requests.size).to eq 1
    click_on 'View'

    expect(data_request_show_page).to be_displayed
    click_on 'Select Day 1 request document'

    expect(commissioning_document_page).to be_displayed
    click_on 'Download Day 1 request document'
    expect(commissioning_document_page.alert.text).to eq('An error has occurred and your document could not be created')
  end
end
