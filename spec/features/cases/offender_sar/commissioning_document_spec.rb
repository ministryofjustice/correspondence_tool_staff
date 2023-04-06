require 'rails_helper'

feature 'commissioning document' do
  given(:manager) { find_or_create :branston_user }
  given(:offender_sar_case) { create(:offender_sar_case).decorate }
  given(:data_request) { create(:data_request, offender_sar_case: offender_sar_case) }

  background do
    login_as manager
  end

  scenario 'Create a commissioning document' do
    data_request_show_page.load(case_id: offender_sar_case.id, id: data_request.id)
    click_on 'Select Day 1 request document'
    expect(new_commissioning_document_page).to be_displayed

    new_commissioning_document_page.form.choose('Prison records')
    click_on 'Generate Day 1 request document'

    record = CommissioningDocument.last
    expect(record.template_name).to eq 'prison'

    expect(data_request_show_page).to be_displayed
    row = data_request_show_page.commissioning_document.row
    expect(row.request_document).to have_text 'Prison records'
    expect(row.sent).to have_text 'No'
  end

  scenario 'Download commissioning document' do
    create(:commissioning_document, data_request: data_request)
    data_request_show_page.load(case_id: offender_sar_case.id, id: data_request.id)
    click_on 'Download'

    expect(page.response_headers['Content-Disposition']).to match(/filename=\".*docx\"/)
  end
end
