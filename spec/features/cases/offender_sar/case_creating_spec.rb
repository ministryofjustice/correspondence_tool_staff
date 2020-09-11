require 'rails_helper'

feature 'Offender SAR Case creation by a manager', js: true do
  given(:manager)         { find_or_create :branston_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }

  background do
    find_or_create :team_branston
    login_as manager
    cases_page.load
  end

  scenario '1 Data subject requesting own record' do
    when_i_navigate_to_offender_sar_subject_page
    and_fill_in_subject_details_page
    and_fill_in_requester_details_page
    and_fill_in_recipient_details_page
    and_fill_in_requested_info_page
    and_fill_in_request_details_page
    and_fill_in_date_received_page
    then_expect_cases_show_page_to_be_correct_for_data_subject_requesting_own_record
    then_expect_open_cases_page_to_be_correct
  end

  scenario '2 Data subject requesting data to be sent to third party' do
    when_i_navigate_to_offender_sar_subject_page
    and_fill_in_subject_details_page
    and_fill_in_requester_details_page
    and_fill_in_recipient_details_page(:third_party)
    and_fill_in_requested_info_page
    and_fill_in_request_details_page
    and_fill_in_date_received_page
    then_expect_cases_show_page_to_be_correct_for_data_subject_sending_data_to_third_party
    then_expect_open_cases_page_to_be_correct
  end

 scenario '3 Solicitor requesting data subject record' do
    when_i_navigate_to_offender_sar_subject_page
    and_fill_in_subject_details_page
    and_fill_in_requester_details_page(:third_party)
    and_fill_in_recipient_details_page(recipient: 'requester_recipient')
    and_fill_in_requested_info_page
    and_fill_in_request_details_page
    and_fill_in_date_received_page
    then_expect_cases_show_page_to_be_correct_for_solicitor_requesting_data_subject_record
    then_expect_open_cases_page_to_be_correct
 end

  scenario '4 Solicitor requesting record to be sent to data subject' do
    when_i_navigate_to_offender_sar_subject_page
    and_fill_in_subject_details_page
    and_fill_in_requester_details_page(:third_party)
    and_fill_in_recipient_details_page(recipient: 'subject_recipient')
    and_fill_in_requested_info_page
    and_fill_in_request_details_page
    and_fill_in_date_received_page
    then_expect_cases_show_page_to_be_correct_for_solicitor_requesting_data_for_data_subject
    then_expect_open_cases_page_to_be_correct
  end

  def then_expect_cases_show_page_to_be_correct_for_solicitor_requesting_data_for_data_subject
    basic_details_of_show_page_are_correct
    expect(cases_show_page).to have_content "Information requested on someone's behalf? Yes"
    expect(cases_show_page).to have_content "Where should the data be sent? The data subject"
    expect_to_have_correct_sending_address
  end

  def then_expect_cases_show_page_to_be_correct_for_solicitor_requesting_data_subject_record
    basic_details_of_show_page_are_correct
    expect(cases_show_page).to have_content "Information requested on someone's behalf? Yes"
    expect(cases_show_page).to have_content "Where should the data be sent? Requester"
    expect_to_have_correct_sending_address
  end

  def then_expect_cases_show_page_to_be_correct_for_data_subject_requesting_own_record
    basic_details_of_show_page_are_correct

    expect(cases_show_page).to have_content "Information requested on someone's behalf? No"
    expect(cases_show_page).to have_content "Where should the data be sent? The data subject"
  end

  def then_expect_cases_show_page_to_be_correct_for_data_subject_sending_data_to_third_party
    basic_details_of_show_page_are_correct

    expect(cases_show_page).to have_content "Information requested on someone's behalf? No"
    expect(cases_show_page).to have_content "Where should the data be sent? Third party"
    expect_to_have_correct_sending_address
  end

  def when_i_navigate_to_offender_sar_subject_page
    expect(cases_page).to have_new_case_button
    cases_page.new_case_button.click
    expect(cases_new_page).to be_displayed

    cases_new_page.create_link_for_correspondence('OFFENDER').click
    expect(cases_new_offender_sar_subject_details_page).to be_displayed
  end

  def and_fill_in_subject_details_page
    cases_new_offender_sar_subject_details_page.fill_in_case_details
    click_on "Continue"
    expect(cases_new_offender_sar_requester_details_page).to be_displayed
  end

  def and_fill_in_requester_details_page(params = nil)
    cases_new_offender_sar_requester_details_page.fill_in_case_details(params)
    click_on "Continue"
    expect(cases_new_offender_sar_recipient_details_page).to be_displayed
  end

  def and_fill_in_recipient_details_page(params = nil)
    cases_new_offender_sar_recipient_details_page.fill_in_case_details(params)
    click_on "Continue"
    expect(cases_new_offender_sar_requested_info_page).to be_displayed
  end

  def and_fill_in_requested_info_page
    cases_new_offender_sar_requested_info_page.fill_in_case_details
    click_on "Continue"
    expect(cases_new_offender_sar_request_details_page).to be_displayed
  end

  def and_fill_in_request_details_page
    cases_new_offender_sar_request_details_page.fill_in_case_details
    click_on "Continue"
    expect(cases_new_offender_sar_date_received_page).to be_displayed
  end

  def and_fill_in_date_received_page
    cases_new_offender_sar_date_received_page.fill_in_case_details
    click_on "Continue"
  end

  def basic_details_of_show_page_are_correct
    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Case created successfully"
    expect(cases_show_page.page_heading).to have_content "Sabrina Adams"
  end

  def then_expect_open_cases_page_to_be_correct
    click_on "Cases"
    expect(open_cases_page).to be_displayed
    expect(cases_page).to have_content "Branston Registry"
    expect(open_cases_page).to have_content "Sabrina Adams"
  end

  def expect_to_have_correct_sending_address
    expect(cases_show_page).to have_content "Representative name Mr J. Smith"
    expect(cases_show_page).to have_content "Company name Foogle and Sons Solicitors at Law"
    expect(cases_show_page).to have_content "Relationship Solicitor"
    expect(cases_show_page).to have_content "Address\n22 High Street"
  end
end

