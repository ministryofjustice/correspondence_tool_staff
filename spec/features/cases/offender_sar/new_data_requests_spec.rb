require 'rails_helper'

feature 'Data Requests for an Offender SAR' do
  given(:manager) { find_or_create :branston_user }
  given(:offender_sar_case) { create(:offender_sar_case).decorate }

  background do
    login_as manager
    cases_page.load
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
    expect(data_requests.size).to eq 5

    request_values.each_with_index do |request, i|
      row = cases_show_page.data_requests.rows[i]
      expect(row.location).to have_text request[:location].strip
      expect(row.data).to have_text request[:data].strip
    end
  end
end
