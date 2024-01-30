require "rails_helper"

feature "Offender SAR Case creation by a manager", js: true do
  given(:manager)         { find_or_create :branston_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }

  background do
    find_or_create :team_branston
    login_as manager
    cases_page.load
  end

  scenario "0 Rejected Data subject requesting own record" do
    when_i_navigate_to_rejected_offender_sar_subject_page
    and_fill_in_subject_details_page
  end

  scenario "1 Data subject requesting own record" do
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

  scenario "2 Data subject requesting data to be sent to third party" do
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

  scenario "3 Solicitor requesting data subject record" do
    when_i_navigate_to_offender_sar_subject_page
    and_fill_in_subject_details_page
    and_fill_in_requester_details_page(:third_party)
    and_fill_in_recipient_details_page(recipient: "requester_recipient")
    and_fill_in_requested_info_page
    and_fill_in_request_details_page
    and_fill_in_date_received_page
    then_expect_cases_show_page_to_be_correct_for_solicitor_requesting_data_subject_record
    then_expect_open_cases_page_to_be_correct
  end

  scenario "4 Solicitor requesting record to be sent to data subject" do
    when_i_navigate_to_offender_sar_subject_page
    and_fill_in_subject_details_page
    and_fill_in_requester_details_page(:third_party)
    and_fill_in_recipient_details_page(recipient: "subject_recipient")
    and_fill_in_requested_info_page
    and_fill_in_request_details_page
    and_fill_in_date_received_page
    then_expect_cases_show_page_to_be_correct_for_solicitor_requesting_data_for_data_subject
    then_expect_open_cases_page_to_be_correct
  end

  scenario "5 clean third party informations when option is changed to data subject" do
    when_i_navigate_to_offender_sar_subject_page
    and_fill_in_subject_details_page(subject_full_name: "6fe2bd8a-ebd2-49a4-b1c9-94955d9472f1")
    and_fill_in_requester_details_page(:third_party)
    and_back_previous_step_to_change_to_non_third_party
    and_fill_in_recipient_details_page(recipient: "subject_recipient")
    and_fill_in_requested_info_page
    and_fill_in_request_details_page
    and_fill_in_date_received_page
    then_expect_cases_show_page_to_be_correct_for_data_subject_requesting_own_record_change(
      "6fe2bd8a-ebd2-49a4-b1c9-94955d9472f1",
    )
    then_expect_no_third_party_info_stored("6fe2bd8a-ebd2-49a4-b1c9-94955d9472f1")
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

  def then_expect_cases_show_page_to_be_correct_for_data_subject_requesting_own_record_change(subject_name)
    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Case created successfully"
    expect(cases_show_page.page_heading).to have_content subject_name

    expect(cases_show_page).to have_content "Information requested on someone's behalf? No"
    expect(cases_show_page).to have_content "Where should the data be sent? The data subject"
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

    cases_new_page.create_link_for_correspondence("Offender SAR").click
    expect(cases_new_offender_sar_subject_details_page).to be_displayed
  end

  def when_i_navigate_to_rejected_offender_sar_subject_page
    expect(cases_page).to have_new_case_button
    cases_page.new_case_button.click
    expect(cases_new_page).to be_displayed
    cases_new_page.create_link_for_correspondence("Rejected Offender SAR - Offender subject access request").click
    expect(cases_new_offender_sar_subject_details_page).to be_displayed
    expect(cases_new_offender_sar_subject_details_page.page_heading.text).to match("Create Rejected Offender SAR case")
  end

  def and_fill_in_subject_details_page(params = nil)
    cases_new_offender_sar_subject_details_page.fill_in_case_details(params)
    scroll_to cases_new_offender_sar_subject_details_page.submit_button
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

  def and_back_previous_step_to_change_to_non_third_party
    click_on "Back"
    and_fill_in_requester_details_page
  end

  def then_expect_no_third_party_info_stored(uniq_subject_full_name)
    kase = Case::Base.where("properties->>'subject_full_name' = ? ", uniq_subject_full_name).first
    expect(kase.third_party).to eq false
    expect(kase.third_party_relationship).to eq ""
    expect(kase.third_party_company_name).to eq ""
    expect(kase.third_party_name).to eq ""
  end
end
