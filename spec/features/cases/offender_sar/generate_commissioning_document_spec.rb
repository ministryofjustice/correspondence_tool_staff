require "rails_helper"

feature "Generate a commissioning document record for a data request" do
  given(:manager) { find_or_create :branston_user }
  given(:offender_sar_case) { create(:offender_sar_case, :waiting_for_data, received_date: 1.working.day.ago).decorate }

  background do
    create(:data_request, offender_sar_case:)
    login_as manager
  end

  scenario "successfully select a template and generate the record" do
    cases_show_page.load(id: offender_sar_case.id)
    data_requests = cases_show_page.data_requests.rows
    expect(data_requests.size).to eq 1
    click_on "View"

    expect(data_request_show_page).to be_displayed
    click_on "Select Day 1 request document"

    expect(new_commissioning_document_page).to be_displayed
    expect(new_commissioning_document_page.form).to have_content("Prison records")
    expect(new_commissioning_document_page.form).to have_content("Security records")
    expect(new_commissioning_document_page.form).to have_content("Probation records")
    expect(new_commissioning_document_page.form).to have_content("CCTV & BWCF")
    expect(new_commissioning_document_page.form).to have_content("Telephone recordings")
    expect(new_commissioning_document_page.form).to have_content("MAPPA")
    expect(new_commissioning_document_page.form).to have_content("PDP")
    expect(new_commissioning_document_page.form).to have_content("CAT A")
    expect(new_commissioning_document_page.form).to have_content("Cross Borders")

    new_commissioning_document_page.form.choose_template_name("prison")
    click_on "Generate Day 1 request document"
    expect(page).to have_content("Day 1 request document selected")
  end

  scenario "attempts to download without selecting a template type" do
    cases_show_page.load(id: offender_sar_case.id)
    data_requests = cases_show_page.data_requests.rows
    expect(data_requests.size).to eq 1
    click_on "View"

    expect(data_request_show_page).to be_displayed
    click_on "Select Day 1 request document"

    expect(new_commissioning_document_page).to be_displayed
    click_on "Generate Day 1 request document"
    expect(page).to have_content("Data request document is required")
  end
end
