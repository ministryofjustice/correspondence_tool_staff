require 'rails_helper'

feature 'Data Requests for an Offender SAR' do
  given(:manager) { find_or_create :branston_user }
  given(:offender_sar_case) { create(:offender_sar_case).decorate }

  background do
    login_as manager
  end

  scenario 'successfully add 5 new requests', js: true do
    cases_show_page.load(id: offender_sar_case.id)
    click_on 'Record data request'
    expect(data_request_page).to be_displayed

    request_values = [
      { location: 'HMP Leicester  ', data: ' A list of meals fed to mo  '},
      { location: 'HMP Brixton', data: 'Latest menu from the clink by chef mo'},
      { location: 'HMP Bronzefield', data: ' Best time to visit mo?'},
      { location: 'HMYP Feltham', data: 'When are you open for mo?'},
      { location: 'Beth Centre', data: 'What is your re-offending rate for mo'},
    ]

    # Page has 3 blank forms to fill in, add 2 more
    click_on 'Add another data request'
    click_on 'Add another data request'

    request_values.each_with_index do |request, i|
      data_request_page.form.location[i].fill_in(with: request[:location])
      data_request_page.form.data[i].fill_in(with: request[:data])
    end

    click_on 'Record requests'

    expect(cases_show_page).to be_displayed
    data_requests = cases_show_page.data_requests.rows
    expect(data_requests.size).to eq 6

    request_values.each_with_index do |request, i|
      row = cases_show_page.data_requests.rows[i]
      expect(row.location).to have_text request[:location].strip
      expect(row.data).to have_text request[:data].strip
      expect(row.date_requested).to have_text Date.current.strftime(Settings.default_date_format)
      expect(row.pages).to have_text '0'
    end

    last_row = cases_show_page.data_requests.rows.last
    expect(last_row).to have_selector '.total-label'
    expect(last_row.total_label).to have_text 'Total'
    expect(last_row).to have_selector '.total-value'
    expect(last_row.total_value).to have_text '0'
  end

  scenario 'total page count is correct', js: true do
    cases_show_page.load(id: offender_sar_case.id)
    click_on 'Record data request'
    expect(data_request_page).to be_displayed

    request_values = [
        { location: 'HMP Leicester  ', data: ' A list of meals fed to mo  '},
        { location: 'HMP Brixton', data: 'Latest menu from the clink by chef mo'},
    ]

    request_values.each_with_index do |request, i|
      data_request_page.form.location[i].fill_in(with: request[:location])
      data_request_page.form.data[i].fill_in(with: request[:data])
    end

    click_on 'Record requests'

    cases_show_page.data_requests.rows[0].click_on 'Update page count'

    data_request_edit_page.form.date_received_dd.fill_in(with: 11)
    data_request_edit_page.form.date_received_mm.fill_in(with: 6)
    data_request_edit_page.form.date_received_yyyy.fill_in(with: 2020)
    data_request_edit_page.form.num_pages.fill_in(with: 32)

    click_on 'Update data received'

    last_row = cases_show_page.data_requests.rows.last
    expect(last_row.total_value).to have_text '32'

    cases_show_page.data_requests.rows[1].click_on 'Update page count'

    data_request_edit_page.form.date_received_dd.fill_in(with: 11)
    data_request_edit_page.form.date_received_mm.fill_in(with: 6)
    data_request_edit_page.form.date_received_yyyy.fill_in(with: 2020)
    data_request_edit_page.form.num_pages.fill_in(with: 128)

    click_on 'Update data received'

    last_row = cases_show_page.data_requests.rows.last
    expect(last_row.total_value).to have_text '160'
  end

  scenario 'partial data entry fails' do
    cases_show_page.load(id: offender_sar_case.id)
    click_on 'Record data request'

    # Note only filling in Location field, ommitting corresponding Data field
    data_request_page.form.location[0].fill_in(with: 'HMP Brixton')
    click_on 'Record requests'

    expect(data_request_page).to be_displayed
    expect(data_request_page).to have_text 'error prevented this form'
  end

  scenario 'no data entry fails' do
    cases_show_page.load(id: offender_sar_case.id)
    click_on 'Record data request'

    data_request_page.form.location[0].fill_in(with: '    ')
    data_request_page.form.data[0].fill_in(with: '')

    click_on 'Record requests'

    expect(data_request_page).to be_displayed
    expect(data_request_page).to have_text 'Ensure Location and Data fields are completed'
  end
end
