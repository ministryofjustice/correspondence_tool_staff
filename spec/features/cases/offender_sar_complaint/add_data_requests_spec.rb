require "rails_helper"

feature "Data Requests for an Offender SAR complaint" do
  given(:manager) { find_or_create :branston_user }
  given(:offender_sar_complaint) { create(:offender_sar_complaint).decorate }
  given!(:contact) { create(:contact) }

  background do
    login_as manager
  end

  scenario "successfully add 2 new requests", js: true do
    cases_show_page.load(id: offender_sar_complaint.id)

    expect(cases_show_page).not_to have_content "Record data request"
    expect(cases_show_page).not_to have_content "Update exempt pages"
    expect(cases_show_page).not_to have_content "Update final page count"

    click_on "Requires data"

    expect(cases_show_page).to have_content "Record data request"
    expect(cases_show_page).to have_content "Update exempt pages"
    expect(cases_show_page).to have_content "Update final page count"

    click_on "Record data request"
    expect(data_request_area_show_page).to be_displayed
    data_request_area_page.form.choose_area_request_type("prison")
    click_on "Continue"

    click_on "Add data request type"
    expect(data_request_page).to be_displayed

    request_values = {
      request_type: "all_prison_records",
      request_type_note: "Lorem ipsum",
      date_requested: Date.new(2020, 8, 15),
      date_from: Date.new(2018, 8, 15),
      date_to: Date.new(2019, 8, 15),
    }

    data_request_page.form.choose_request_type(request_values[:request_type])
    data_request_page.form.set_date_requested(request_values[:date_requested])
    data_request_page.form.set_date_from(request_values[:date_from])
    data_request_page.form.set_date_to(request_values[:date_to])
    click_on "Continue"

    record = DataRequest.last
    expect(record.request_type).to eq "all_prison_records"
    expect(record.request_type_note).to eq ""
    expect(record.date_from).to eq Date.new(2018, 8, 15)
    expect(record.date_to).to eq Date.new(2019, 8, 15)

    expect(data_request_area_show_page).to be_displayed
    row = data_request_area_show_page.data_requests.rows[0]
    expect(row.request_type).to have_text request_values[:request_type].strip.humanize
    expect(row.date_requested).to have_text "15 Aug 2020"
    expect(row.pages).to have_text "0"

    click_on "Add data request type"
    data_request_page.form.choose_request_type("other")
    data_request_page.form.request_type_note.fill_in(with: request_values[:request_type_note])
    data_request_page.form.set_date_requested(request_values[:date_requested])
    click_on "Continue"

    expect(data_request_area_show_page).to be_displayed
    row = data_request_area_show_page.data_requests.rows[1]
    expect(row.request_type).to have_text "Other"
    expect(row.request_type).to have_text "Lorem ipsum"
    expect(row.date_requested).to have_text "15 Aug 2020"

    expect(data_request_area_show_page.data_requests.find(".total-label").text).to have_text "Total"
    expect(data_request_area_show_page.data_requests.find(".total-value").text).to have_text "0"
  end

  scenario "partial data entry fails" do
    cases_show_page.load(id: offender_sar_complaint.id)
    click_on "Requires data"

    click_on "Record data request"
    data_request_area_page.form.choose_area_request_type("prison")
    click_on "Continue"

    click_on "Add data request type"
    data_request_page.form.set_date_requested(Date.new(2020, 8, 15))
    data_request_page.form.set_date_from(Date.new(2020, 8, 15))
    data_request_page.form.set_date_to(Date.new(2020, 8, 15))
    click_on "Continue"

    expect(data_request_page).to be_displayed
    expect(data_request_page).to have_text "error prevented this form"
    expect(data_request_page).to have_text "Data requests request type cannot be blank"
  end

  scenario "no data entry fails" do
    cases_show_page.load(id: offender_sar_complaint.id)
    click_on "Requires data"
    click_on "Record data request"

    data_request_area_page.form.choose_area_request_type("prison")
    click_on "Continue"
    expect(data_request_area_show_page).to be_displayed

    click_on "Add data request type"
    click_on "Continue"

    expect(data_request_page).to have_text "2 errors prevented this form from being submitted"
    expect(data_request_page).to have_text "Data requests request type cannot be blank"
    expect(data_request_page).to have_text "Data requests date requested can't be blank"
  end

  scenario "record data request with data type of NOMIS other and notes", js: true do
    request_values = {
      request_type: "all_prison_records",
      request_type_note: "Testing nomis-other note",
      date_requested: Date.new(2020, 8, 15),
      date_from: Date.new(2018, 8, 15),
      date_to: Date.new(2019, 8, 15),
    }

    cases_show_page.load(id: offender_sar_complaint.id)
    click_on "Requires data"

    record_a_data_request_of_nomis_other(request_values)
    validate_nomis_other_info(request_values)
  end
end
