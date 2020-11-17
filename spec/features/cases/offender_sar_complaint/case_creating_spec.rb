require 'rails_helper'

feature 'offender sar complaint case creation by a manager', js: true do
  given(:manager)         { find_or_create :branston_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }
  given(:offender_sar) { create :offender_sar_case, :third_party, :closed}

  background do
    find_or_create :team_branston
    login_as manager
    cases_page.load
  end

  scenario '1 find the original offender sar case' do
    when_i_navigate_to_offender_sar_compplaint_subject_page
    and_choose_original_offender_sar_case_and_confirm
    and_fill_in_requester_details_page
    and_fill_in_recipient_details_page
    and_fill_in_requested_info_page
    and_fill_in_request_details_page
    and_fill_in_date_received_page
    then_expect_cases_show_page_to_be_correct_for_data_subject_requesting_own_record
    then_expect_open_cases_page_to_be_correct
  end

  scenario '2 Data subject requesting data to be sent to third party' do
    when_i_navigate_to_offender_sar_compplaint_subject_page
    and_choose_original_offender_sar_case_and_confirm
    and_fill_in_requester_details_page
    and_fill_in_recipient_details_page(:third_party)
    and_fill_in_requested_info_page
    and_fill_in_request_details_page
    and_fill_in_date_received_page
    then_expect_cases_show_page_to_be_correct_for_data_subject_sending_data_to_third_party
    then_expect_open_cases_page_to_be_correct
  end

 scenario '3 Solicitor requesting data subject record' do
    when_i_navigate_to_offender_sar_compplaint_subject_page
    and_choose_original_offender_sar_case_and_confirm
    and_fill_in_requester_details_page(:third_party)
    and_fill_in_recipient_details_page(recipient: 'requester_recipient')
    and_fill_in_requested_info_page
    and_fill_in_request_details_page
    and_fill_in_date_received_page
    then_expect_cases_show_page_to_be_correct_for_solicitor_requesting_data_subject_record
    then_expect_open_cases_page_to_be_correct
 end

  scenario '4 Solicitor requesting record to be sent to data subject' do
    when_i_navigate_to_offender_sar_compplaint_subject_page
    and_choose_original_offender_sar_case_and_confirm
    and_fill_in_requester_details_page(:third_party)
    and_fill_in_recipient_details_page(recipient: 'subject_recipient')
    and_fill_in_requested_info_page
    and_fill_in_request_details_page
    and_fill_in_date_received_page
    then_expect_cases_show_page_to_be_correct_for_solicitor_requesting_data_for_data_subject
    then_expect_open_cases_page_to_be_correct
  end

  scenario '5 Copy the third part details from linked offender sar case' do
    when_i_navigate_to_offender_sar_compplaint_subject_page
    and_choose_original_offender_sar_case_and_confirm
    click_on "Continue"
    click_on "Continue"
    and_fill_in_requested_info_page
    and_fill_in_request_details_page
    and_fill_in_date_received_page
    then_expect_cases_show_page_to_have_same_third_party_detail
    then_expect_open_cases_page_to_be_correct
  end

  def then_expect_cases_show_page_to_have_same_third_party_detail
    basic_details_of_show_page_are_correct
    expect(cases_show_page).to have_content "Information requested on someone's behalf? Yes"
    expect(cases_show_page).to have_content offender_sar.third_party_relationship
    expect(cases_show_page).to have_content offender_sar.third_party_company_name
    expect(cases_show_page).to have_content offender_sar.third_party_name
    expect(cases_show_page).to have_content "Where should the data be sent? Requester"
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

  def when_i_navigate_to_offender_sar_compplaint_subject_page
    expect(cases_page).to have_new_case_button
    cases_page.new_case_button.click
    expect(cases_new_page).to be_displayed
    cases_new_page.create_link_for_correspondence('OFFENDER-SAR-COMPLAINT').click
    expect(cases_new_offender_sar_complaint_link_offender_sar_page).to have_content "Create OFFENDER-SAR-COMPLAINT case"
    expect(cases_new_offender_sar_complaint_link_offender_sar_page).to be_displayed
  end

  def and_choose_original_offender_sar_case_and_confirm
    cases_new_offender_sar_complaint_link_offender_sar_page.fill_in_original_case_number(offender_sar.number)
    click_on "Continue"
    expect(cases_new_offender_sar_complaint_confirm_case_page).to have_content "Create OFFENDER-SAR-COMPLAINT case"
    expect(cases_new_offender_sar_complaint_confirm_case_page).to be_displayed
    cases_new_offender_sar_complaint_confirm_case_page.confirm_yes
    click_on "Continue"
  end

  def and_fill_in_requester_details_page(params = nil)
    cases_new_offender_sar_complaint_requester_details_page.fill_in_case_details(params)
    click_on "Continue"
    expect(cases_new_offender_sar_complaint_recipient_details_page).to have_content "Create OFFENDER-SAR-COMPLAINT case"
    expect(cases_new_offender_sar_complaint_recipient_details_page).to be_displayed
  end

  def and_fill_in_recipient_details_page(params = nil)
    cases_new_offender_sar_complaint_recipient_details_page.fill_in_case_details(params)
    click_on "Continue"
    expect(cases_new_offender_sar_complaint_requested_info_page).to have_content "Create OFFENDER-SAR-COMPLAINT case"
    expect(cases_new_offender_sar_complaint_requested_info_page).to be_displayed
  end

  def and_fill_in_requested_info_page
    cases_new_offender_sar_complaint_requested_info_page.fill_in_case_details
    click_on "Continue"
    expect(cases_new_offender_sar_complaint_request_details_page).to have_content "Create OFFENDER-SAR-COMPLAINT case"
    expect(cases_new_offender_sar_complaint_request_details_page).to be_displayed
  end

  def and_fill_in_request_details_page
    cases_new_offender_sar_complaint_request_details_page.fill_in_case_details
    click_on "Continue"
    expect(cases_new_offender_sar_complaint_date_received_page).to have_content "Create OFFENDER-SAR-COMPLAINT case"
    expect(cases_new_offender_sar_complaint_date_received_page).to be_displayed
  end

  def and_fill_in_date_received_page
    cases_new_offender_sar_complaint_date_received_page.fill_in_case_details
    click_on "Continue"
  end

  def basic_details_of_show_page_are_correct
    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "OFFENDER-SAR-COMPLAINT"
    expect(cases_show_page).to have_content "Case created successfully"
    expect(cases_show_page.page_heading).to have_content offender_sar.subject
    expect(cases_show_page).to have_content offender_sar.subject_full_name
    expect(cases_show_page).to have_content offender_sar.date_of_birth.strftime("%d %b %Y")
    expect(cases_show_page).to have_content offender_sar.prison_number
    expect(cases_show_page).to have_content offender_sar.subject_type.humanize
    expect(cases_show_page).to have_content offender_sar.subject_address
  end

  def then_expect_open_cases_page_to_be_correct
    click_on "Cases"
    expect(open_cases_page).to be_displayed
    expect(cases_page).to have_content "Branston Registry"
    expect(open_cases_page).to have_content offender_sar.subject
  end

  def expect_to_have_correct_sending_address
    expect(cases_show_page).to have_content "Representative name Mr J. Smith"
    expect(cases_show_page).to have_content "Company name Foogle and Sons Solicitors at Law"
    expect(cases_show_page).to have_content "Relationship Solicitor"
    expect(cases_show_page).to have_content "Address\n22 High Street"
  end
end

