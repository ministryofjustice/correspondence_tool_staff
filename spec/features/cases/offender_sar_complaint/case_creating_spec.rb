require "rails_helper"

feature "offender sar complaint case creation by a manager", js: true do
  given(:manager)         { find_or_create :branston_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }
  given(:offender_sar) { create :offender_sar_case, :third_party, :closed }
  given(:complaint_type) { "standard_complaint" }
  given(:complaint_subtype) { Case::SAR::OffenderComplaint.complaint_subtypes.keys.sample }
  given(:complaint_priority) { Case::SAR::OffenderComplaint.priorities.keys.sample }
  given(:default_params) { { complaint_type:, complaint_subtype:, priority: complaint_priority } }
  given(:target_case) { build_stubbed(:offender_sar_complaint, default_params).decorate }

  background do
    find_or_create :team_branston
    login_as manager
    cases_page.load
  end

  scenario "1 find the original offender sar case" do
    when_i_navigate_to_offender_sar_complaint_subject_page
    and_choose_original_offender_sar_case_and_confirm
    and_fill_in_complaint_type_page
    and_fill_in_requester_details_page
    and_fill_in_recipient_details_page
    and_fill_in_requested_info_page
    and_fill_in_request_details_page
    and_fill_in_date_received_page
    and_fill_in_external_deadline_page
    then_basic_details_of_show_page_are_correct
    then_expect_case_show_page_to_show_standard
    then_expect_cases_show_page_to_be_correct_for_data_subject_requesting_own_record
    then_expect_linked_original_case_has_stamp_for_linkage
    then_expect_open_cases_page_to_be_correct
    then_expect_case_in_my_open_cases
  end

  scenario "2 Data subject requesting data to be sent to third party" do
    when_i_navigate_to_offender_sar_complaint_subject_page
    and_choose_original_offender_sar_case_and_confirm
    and_fill_in_complaint_type_page
    and_fill_in_requester_details_page
    and_fill_in_recipient_details_page(:third_party)
    and_fill_in_requested_info_page
    and_fill_in_request_details_page
    and_fill_in_date_received_page
    and_fill_in_external_deadline_page
    then_basic_details_of_show_page_are_correct
    then_expect_case_show_page_to_show_standard
    then_expect_cases_show_page_to_be_correct_for_data_subject_sending_data_to_third_party
    then_expect_linked_original_case_has_stamp_for_linkage
    then_expect_open_cases_page_to_be_correct
    then_expect_case_in_my_open_cases
  end

  scenario "3 Solicitor requesting data subject record" do
    when_i_navigate_to_offender_sar_complaint_subject_page
    and_choose_original_offender_sar_case_and_confirm
    and_fill_in_complaint_type_page
    and_fill_in_requester_details_page(:third_party)
    and_fill_in_recipient_details_page(recipient: "requester_recipient")
    and_fill_in_requested_info_page
    and_fill_in_request_details_page
    and_fill_in_date_received_page
    and_fill_in_external_deadline_page
    then_basic_details_of_show_page_are_correct
    then_expect_case_show_page_to_show_standard
    then_expect_cases_show_page_to_be_correct_for_solicitor_requesting_data_subject_record
    then_expect_linked_original_case_has_stamp_for_linkage
    then_expect_open_cases_page_to_be_correct
    then_expect_case_in_my_open_cases
  end

  scenario "4 Solicitor requesting record to be sent to data subject" do
    when_i_navigate_to_offender_sar_complaint_subject_page
    and_choose_original_offender_sar_case_and_confirm
    and_fill_in_complaint_type_page
    and_fill_in_requester_details_page(:third_party)
    and_fill_in_recipient_details_page(recipient: "subject_recipient")
    and_fill_in_requested_info_page
    and_fill_in_request_details_page
    and_fill_in_date_received_page
    and_fill_in_external_deadline_page
    then_basic_details_of_show_page_are_correct
    then_expect_case_show_page_to_show_standard
    then_expect_cases_show_page_to_be_correct_for_solicitor_requesting_data_for_data_subject
    then_expect_linked_original_case_has_stamp_for_linkage
    then_expect_open_cases_page_to_be_correct
    then_expect_case_in_my_open_cases
  end

  scenario "5 Copy the third part details from linked offender sar case" do
    when_i_navigate_to_offender_sar_complaint_subject_page
    and_choose_original_offender_sar_case_and_confirm
    and_fill_in_complaint_type_page
    click_on "Continue"
    click_on "Continue"
    and_fill_in_requested_info_page
    and_fill_in_request_details_page
    and_fill_in_date_received_page
    and_fill_in_external_deadline_page
    then_basic_details_of_show_page_are_correct
    then_expect_case_show_page_to_show_standard
    then_expect_cases_show_page_to_have_same_third_party_detail
    then_expect_linked_original_case_has_stamp_for_linkage
    then_expect_open_cases_page_to_be_correct
    then_expect_case_in_my_open_cases
  end

  scenario "6 Create the complaint case from closed offender sar case" do
    when_i_navigate_to_offender_sar_subject_page_and_start_complaint
    and_confirm_offender_sar_case
    and_fill_in_complaint_type_page
    click_on "Continue"
    click_on "Continue"
    and_fill_in_requested_info_page
    and_fill_in_request_details_page
    and_fill_in_date_received_page
    and_fill_in_external_deadline_page
    then_basic_details_of_show_page_are_correct
    then_expect_case_show_page_to_show_standard
    then_expect_cases_show_page_to_have_same_third_party_detail
    then_expect_open_cases_page_to_be_correct
    then_expect_case_in_my_open_cases
  end

  scenario "7 Create the complaint case from open late offender sar case" do
    offender_sar_open_late = create(:offender_sar_case, :third_party, received_date: Date.new(2017, 1, 4))
    when_i_navigate_to_offender_sar_subject_page_and_start_complaint(offender_sar_case: offender_sar_open_late)
    and_confirm_offender_sar_case
    and_fill_in_complaint_type_page
    and_fill_in_requester_details_page(:third_party)
    and_fill_in_recipient_details_page(recipient: "subject_recipient")
    and_fill_in_requested_info_page
    and_fill_in_request_details_page
    and_fill_in_date_received_page
    and_fill_in_external_deadline_page
    then_basic_details_of_show_page_are_correct(offender_sar_case: offender_sar_open_late)
    then_expect_case_show_page_to_show_standard
    then_expect_cases_show_page_to_be_correct_for_solicitor_requesting_data_for_data_subject
    then_expect_linked_original_case_has_stamp_for_linkage(offender_sar_case: offender_sar_open_late)
    then_expect_open_cases_page_to_be_correct(offender_sar_case: offender_sar_open_late)
    then_expect_case_in_my_open_cases
  end

  scenario "8 Create the complaint case from open in time offender sar case" do
    offender_sar_open_in_time = create(:offender_sar_case, :third_party)
    then_expect_no_button_for_creating_complaint_case(offender_sar_open_in_time)
  end

  scenario "9 back to offender sar case page when creating complaint from its page " do
    when_i_navigate_to_offender_sar_subject_page_and_start_complaint
    and_click_back_link
    then_expect_back_to_offender_sar_page_again
  end

  scenario "10 back to case choice page when creating complaint from choice page " do
    when_i_navigate_to_offender_sar_complaint_subject_page
    and_click_back_link
    expect(cases_new_page).to be_displayed
  end

  scenario "11 clean third party informations when option is changed to data subject" do
    offender_sar1 = create(:offender_sar_case, subject_full_name: "db22f64a-0371-4593-a5a8-1d9c7c8ae8e0")
    when_i_navigate_to_offender_sar_complaint_subject_page
    and_choose_original_offender_sar_case_and_confirm(offender_sar1.number)
    and_fill_in_complaint_type_page
    and_fill_in_requester_details_page(:third_party)
    and_back_previous_step_to_change_to_non_third_party
    and_fill_in_recipient_details_page(recipient: "subject_recipient")
    and_fill_in_requested_info_page
    and_fill_in_request_details_page
    and_fill_in_date_received_page
    and_fill_in_external_deadline_page

    then_basic_details_of_show_page_are_correct(offender_sar_case: offender_sar1)
    then_expect_cases_show_page_to_be_correct_for_data_subject_requesting_own_record
    then_expect_no_third_party_info_stored("db22f64a-0371-4593-a5a8-1d9c7c8ae8e0")
  end

  context "when complaint is an ICO complaint" do
    let(:complaint_type) { "ico_complaint" }

    scenario "9 when complaint is an ICO complaint" do
      when_i_navigate_to_offender_sar_complaint_subject_page
      and_choose_original_offender_sar_case_and_confirm
      and_fill_in_complaint_type_page
      and_fill_in_requester_details_page
      and_fill_in_recipient_details_page
      and_fill_in_requested_info_page
      and_fill_in_request_details_page
      and_fill_in_date_received_page
      and_fill_in_external_deadline_page
      then_basic_details_of_show_page_are_correct
      then_expect_case_show_page_to_show_ico
      then_expect_cases_show_page_to_be_correct_for_data_subject_requesting_own_record
      then_expect_linked_original_case_has_stamp_for_linkage
      then_expect_open_cases_page_to_be_correct
      then_expect_case_in_my_open_cases
    end
  end

  context "when complaint is a litigation complaint" do
    let(:complaint_type) { "litigation_complaint" }

    scenario "10 when complaint is a litigation complaint" do
      when_i_navigate_to_offender_sar_complaint_subject_page
      and_choose_original_offender_sar_case_and_confirm
      and_fill_in_complaint_type_page
      and_fill_in_requester_details_page
      and_fill_in_recipient_details_page
      and_fill_in_requested_info_page
      and_fill_in_request_details_page
      and_fill_in_date_received_page
      and_fill_in_external_deadline_page
      then_basic_details_of_show_page_are_correct
      then_expect_case_show_page_to_show_litigation
      then_expect_cases_show_page_to_be_correct_for_data_subject_requesting_own_record
      then_expect_linked_original_case_has_stamp_for_linkage
      then_expect_open_cases_page_to_be_correct
      then_expect_case_in_my_open_cases
    end
  end

  describe "standard" do
    let(:complaint_type) { "standard_complaint" }

    scenario "11 Check the deadline will be prefilled when complaint_type is standard" do
      Timecop.freeze Time.utc(2017, 5, 18, 12, 0, 0) do
        when_i_navigate_to_offender_sar_complaint_subject_page
        and_choose_original_offender_sar_case_and_confirm
        and_fill_in_complaint_type_page
        and_fill_in_requester_details_page
        and_fill_in_recipient_details_page
        and_fill_in_requested_info_page
        and_fill_in_request_details_page
        and_fill_in_date_received_page
        and_fill_and_check_external_deadline_is_prefilled(16, 6, 2017)
        then_basic_details_of_show_page_are_correct
        then_expect_cases_show_page_to_be_correct_for_data_subject_requesting_own_record
        then_expect_linked_original_case_has_stamp_for_linkage
        then_expect_open_cases_page_to_be_correct
        then_expect_case_in_my_open_cases
      end
    end
  end

  describe "ICO" do
    let(:complaint_type) { "ico_complaint" }

    scenario "10 Check the deadline will be not prefilled when complaint_type is ico" do
      Timecop.freeze Time.utc(2017, 5, 18, 12, 0, 0) do
        when_i_navigate_to_offender_sar_complaint_subject_page
        and_choose_original_offender_sar_case_and_confirm
        and_fill_in_complaint_type_page
        and_fill_in_requester_details_page
        and_fill_in_recipient_details_page
        and_fill_in_requested_info_page
        and_fill_in_request_details_page
        and_fill_in_date_received_page
        and_fill_and_check_external_deadline_is_prefilled("", "", "", external_deadline: Time.zone.today + 10.days)
        then_basic_details_of_show_page_are_correct
        then_expect_cases_show_page_to_be_correct_for_data_subject_requesting_own_record
        then_expect_linked_original_case_has_stamp_for_linkage
        then_expect_open_cases_page_to_be_correct
        then_expect_case_in_my_open_cases
      end
    end
  end

  describe "litigation" do
    let(:complaint_type) { "litigation_complaint" }

    scenario "11 Check the deadline will be not prefilled when complaint_type is litigation" do
      Timecop.freeze Time.utc(2017, 5, 18, 12, 0, 0) do
        @chosen_complaint_type = "litigation_complaint"
        when_i_navigate_to_offender_sar_complaint_subject_page
        and_choose_original_offender_sar_case_and_confirm
        and_fill_in_complaint_type_page
        and_fill_in_requester_details_page
        and_fill_in_recipient_details_page
        and_fill_in_requested_info_page
        and_fill_in_request_details_page
        and_fill_in_date_received_page
        and_fill_and_check_external_deadline_is_prefilled("", "", "", external_deadline: Time.zone.today + 10.days)
        then_basic_details_of_show_page_are_correct
        then_expect_cases_show_page_to_be_correct_for_data_subject_requesting_own_record
        then_expect_linked_original_case_has_stamp_for_linkage
        then_expect_open_cases_page_to_be_correct
        then_expect_case_in_my_open_cases
      end
    end
  end

  def then_expect_no_button_for_creating_complaint_case(offender_sar_case)
    click_on "Cases"
    open_cases_page.load
    click_link offender_sar_case.number
    expect(cases_show_page).to be_displayed
    expect(cases_show_page).not_to have_content "Start complaint"
  end

  def then_expect_cases_show_page_to_have_same_third_party_detail
    expect(cases_show_page).to have_content "Information requested on someone's behalf? Yes"
    expect(cases_show_page).to have_content offender_sar.third_party_relationship
    expect(cases_show_page).to have_content offender_sar.third_party_company_name
    expect(cases_show_page).to have_content offender_sar.third_party_name
    expect(cases_show_page).to have_content "Where should the data be sent? Requester"
  end

  def then_expect_cases_show_page_to_be_correct_for_solicitor_requesting_data_for_data_subject
    expect(cases_show_page).to have_content "Information requested on someone's behalf? Yes"
    expect(cases_show_page).to have_content "Where should the data be sent? The data subject"
    expect_to_have_correct_sending_address
  end

  def then_expect_cases_show_page_to_be_correct_for_solicitor_requesting_data_subject_record
    expect(cases_show_page).to have_content "Information requested on someone's behalf? Yes"
    expect(cases_show_page).to have_content "Where should the data be sent? Requester"
    expect_to_have_correct_sending_address
  end

  def then_expect_cases_show_page_to_be_correct_for_data_subject_requesting_own_record
    expect(cases_show_page).to have_content "Information requested on someone's behalf? No"
    expect(cases_show_page).to have_content "Where should the data be sent? The data subject"
  end

  def then_expect_cases_show_page_to_be_correct_for_data_subject_sending_data_to_third_party
    expect(cases_show_page).to have_content "Information requested on someone's behalf? No"
    expect(cases_show_page).to have_content "Where should the data be sent? Third party"
    expect_to_have_correct_sending_address
  end

  def then_expect_linked_original_case_has_stamp_for_linkage(offender_sar_case: nil)
    cases_show_page.link_case.linked_records.first.link.click
    expect(cases_show_page).to be_displayed(id: (offender_sar_case || offender_sar).id)
    expect(cases_show_page.case_history.entries.first)
      .to have_content I18n.t(
        "common.case/offender_sar.complaint_case_link_message",
        received_date: Time.zone.today,
      )
  end

  def when_i_navigate_to_offender_sar_subject_page_and_start_complaint(offender_sar_case: nil)
    link_case = offender_sar_case || offender_sar
    click_on "Cases"
    open_cases_page.load
    if link_case.current_state == "closed"
      click_on "Closed cases"
    end
    click_link link_case.number
    expect(cases_show_page).to be_displayed
    click_on "Start complaint"
  end

  def when_i_navigate_to_offender_sar_complaint_subject_page
    expect(cases_page).to have_new_case_button
    cases_page.new_case_button.click
    expect(cases_new_page).to be_displayed
    cases_new_page.create_link_for_correspondence("Offender SAR complaint").click
    expect(cases_new_offender_sar_complaint_link_offender_sar_page).to have_content "Create Offender SAR Complaint case"
    expect(cases_new_offender_sar_complaint_link_offender_sar_page).to be_displayed
  end

  def and_choose_original_offender_sar_case_and_confirm(case_number = nil)
    cases_new_offender_sar_complaint_link_offender_sar_page.fill_in_original_case_number(case_number || offender_sar.number)
    click_on "Continue"
    expect(cases_new_offender_sar_complaint_confirm_case_page).to have_content "Create Offender SAR Complaint case"
    expect(cases_new_offender_sar_complaint_confirm_case_page).to be_displayed
    expect(cases_new_offender_sar_complaint_confirm_case_page.back_links.size).to eq 2
    cases_new_offender_sar_complaint_confirm_case_page.confirm_yes
    click_on "Continue"
  end

  def and_confirm_offender_sar_case
    expect(cases_new_offender_sar_complaint_confirm_case_page).to have_content "Create Offender SAR Complaint case"
    expect(cases_new_offender_sar_complaint_confirm_case_page).to be_displayed
    cases_new_offender_sar_complaint_confirm_case_page.confirm_yes
    click_on "Continue"
  end

  def and_fill_in_complaint_type_page
    expect(cases_new_offender_sar_complaint_complaint_type_page).to be_displayed
    cases_new_offender_sar_complaint_complaint_type_page.fill_in_case_details(default_params)
    click_on "Continue"
  end

  def and_fill_in_requester_details_page(params = nil)
    expect(cases_new_offender_sar_complaint_requester_details_page).to be_displayed
    cases_new_offender_sar_complaint_requester_details_page.fill_in_case_details(params)
    click_on "Continue"
    expect(cases_new_offender_sar_complaint_recipient_details_page).to have_content "Complaint - #{target_case.complaint_type}"
    expect(cases_new_offender_sar_complaint_recipient_details_page).to be_displayed
  end

  def and_fill_in_recipient_details_page(params = nil)
    cases_new_offender_sar_complaint_recipient_details_page.fill_in_case_details(params)
    click_on "Continue"
    expect(cases_new_offender_sar_complaint_requested_info_page).to have_content "Complaint - #{target_case.complaint_type}"
    expect(cases_new_offender_sar_complaint_requested_info_page).to be_displayed
  end

  def and_fill_in_requested_info_page
    cases_new_offender_sar_complaint_requested_info_page.fill_in_case_details
    click_on "Continue"
    expect(cases_new_offender_sar_complaint_request_details_page).to have_content "Complaint - #{target_case.complaint_type}"
    expect(cases_new_offender_sar_complaint_request_details_page).to be_displayed
  end

  def and_fill_in_request_details_page
    cases_new_offender_sar_complaint_request_details_page.fill_in_case_details
    click_on "Continue"
    expect(cases_new_offender_sar_complaint_date_received_page).to have_content "Complaint - #{target_case.complaint_type}"
    expect(cases_new_offender_sar_complaint_date_received_page).to be_displayed
  end

  def and_fill_in_date_received_page
    cases_new_offender_sar_complaint_date_received_page.fill_in_case_details
    click_on "Continue"
  end

  def and_fill_in_external_deadline_page
    if @chosen_complaint_type == "standard_complaint"
      cases_new_offender_sar_complaint_external_deadline_page.fill_in_case_details
    else
      cases_new_offender_sar_complaint_external_deadline_page.fill_in_case_details(external_deadline: Time.zone.today + 10.days)
    end
    click_on "Continue"
  end

  def and_fill_and_check_external_deadline_is_prefilled(day, month, year, external_deadline: nil)
    expect(cases_new_offender_sar_complaint_external_deadline_page.external_deadline_day.value).to eq day.to_s
    expect(cases_new_offender_sar_complaint_external_deadline_page.external_deadline_month.value).to eq month.to_s
    expect(cases_new_offender_sar_complaint_external_deadline_page.external_deadline_year.value).to eq year.to_s
    cases_new_offender_sar_complaint_external_deadline_page.fill_in_case_details(external_deadline:)
    click_on "Continue"
  end

  def then_basic_details_of_show_page_are_correct(offender_sar_case: nil)
    linked_case = offender_sar_case || offender_sar
    expect(cases_show_page).to be_displayed
    expect_the_case_to_be_assigned_to_me
    expect(cases_show_page).to have_content "Case created successfully"
    expect(cases_show_page.page_heading).to have_content linked_case.subject
    expect(cases_show_page).to have_content linked_case.subject_full_name
    expect(cases_show_page).to have_content linked_case.date_of_birth.strftime("%d %b %Y")
    expect(cases_show_page).to have_content linked_case.prison_number
    expect(cases_show_page).to have_content linked_case.subject_type.humanize
    expect(cases_show_page).to have_content linked_case.subject_address
    expect(cases_show_page).to have_content target_case.complaint_type
    expect(cases_show_page)
    .to have_content I18n.t(
      "helpers.label.offender_sar_complaint.complaint_subtype.#{target_case.complaint_subtype}",
    )
    expect(cases_show_page).to have_content target_case.priority.humanize
  end

  def then_expect_case_show_page_to_show_standard
    expect(cases_show_page.offender_sar_complaint_type).to have_content "Standard"
  end

  def then_expect_case_show_page_to_show_ico
    expect(cases_show_page.offender_sar_complaint_type).to have_content "ICO"
    expect(cases_show_page.offender_sar_complaint_ico_contact_name).to have_content "Jane Doe ICO"
    expect(cases_show_page.offender_sar_complaint_ico_contact_email).to have_content "jane_doe_ico@example.com"
    expect(cases_show_page.offender_sar_complaint_ico_contact_phone).to have_content "01234 567 9876"
    expect(cases_show_page.offender_sar_complaint_ico_reference).to have_content "ICOREF001Z"
  end

  def then_expect_case_show_page_to_show_litigation
    expect(cases_show_page.offender_sar_complaint_type).to have_content "Litigation"
    expect(cases_show_page.offender_sar_complaint_gld_contact_name).to have_content "Priya Singh Litigation"
    expect(cases_show_page.offender_sar_complaint_gld_contact_email).to have_content "priya_singh_litigation@example.com"
    expect(cases_show_page.offender_sar_complaint_gld_contact_phone).to have_content "01234 824 9876"
    expect(cases_show_page.offender_sar_complaint_gld_reference).to have_content "LITREF732K"
  end

  def then_expect_open_cases_page_to_be_correct(offender_sar_case: nil)
    click_on "Cases"
    expect(open_cases_page).to be_displayed
    expect(open_cases_page).to have_content "branston registry responding user"
    expect(open_cases_page).to have_content (offender_sar_case || offender_sar).subject
  end

  def expect_to_have_correct_sending_address
    expect(cases_show_page).to have_content "Representative name Mr J. Smith"
    expect(cases_show_page).to have_content "Company name Foogle and Sons Solicitors at Law"
    expect(cases_show_page).to have_content "Relationship Solicitor"
    expect(cases_show_page).to have_content "Address\n22 High Street"
  end

  def expect_the_case_to_be_assigned_to_me
    expect(cases_show_page.case_history).to have_content "Assign responder"
    expect(cases_show_page.case_history).to have_content "Self-assigned this case to branston registry responding user"
    expect(cases_show_page).to have_content "With\nbranston registry responding user"
  end

  def then_expect_case_in_my_open_cases
    complaint_case = Case::Base.offender_sar_complaint.last
    click_on "My open cases"
    expect(my_open_cases_page).to be_displayed
    row = my_open_cases_page.row_for_case_number(complaint_case.number)
    expect(row).to have_content complaint_case.number
    expect(row).to have_content "branston registry responding user"
  end

  def and_click_back_link
    cases_new_offender_sar_complaint_confirm_case_page.find_first_back_link.click
  end

  def then_expect_back_to_offender_sar_page_again
    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content offender_sar.number
    expect(cases_show_page).to have_content "Start complaint"
  end

  def and_back_previous_step_to_change_to_non_third_party
    click_on "Back"
    and_fill_in_requester_details_page
  end

  def then_expect_no_third_party_info_stored(uniq_subject_full_name)
    kase = Case::SAR::OffenderComplaint.where("properties->>'subject_full_name' = ? ", uniq_subject_full_name).first
    expect(kase.third_party).to eq false
    expect(kase.third_party_relationship).to eq ""
    expect(kase.third_party_company_name).to eq ""
    expect(kase.third_party_name).to eq ""
  end
end
