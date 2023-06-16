require "rails_helper"
require File.join(Rails.root, "db", "seeders", "case_category_reference_seeder")

feature "Offender SAR Case creation by a manager" do
  given(:manager)         { find_or_create :branston_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }
  given(:offender_sar_case) { create(:offender_sar_case).decorate }
  given(:late_offender_sar_case) { create(:offender_sar_case, received_date: 2.months.ago).decorate }

  background do
    find_or_create :team_branston
    login_as manager
    cases_page.load
    CaseClosure::MetadataSeeder.seed!
    CaseCategoryReferenceSeeder::ReasonsForLateness.seed!
  end

  after do
    CaseClosure::MetadataSeeder.unseed!
  end

  scenario "progressing an offender sar case" do
    cases_show_page.load(id: offender_sar_case.id)

    expect(cases_show_page).to have_content "Mark as waiting for data"
    expect(cases_show_page).to have_content "Data to be requested"
    expect(cases_show_page).to have_content "Send acknowledgement letter"
    click_on "Mark as waiting for data"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Mark as ready for vetting"
    expect(cases_show_page).to have_content "Send acknowledgement letter"
    expect(cases_show_page).to have_content "Preview cover page"
    click_on "Mark as ready for vetting"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Mark as vetting in progress"
    expect(cases_show_page).to have_content "Preview cover page"
    expect(cases_show_page).to have_content "Sent to SSCL"
    click_on "Mark as vetting in progress"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Mark as ready to copy"
    expect(cases_show_page).to have_content "Preview cover page"
    expect(cases_show_page).to have_content "Sent to SSCL"
    click_on "Mark as ready to copy"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Mark as ready to dispatch"
    expect(cases_show_page).to have_content "Sent to SSCL"
    click_on "Mark as ready to dispatch"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Send dispatch letter"
    expect(cases_show_page).to have_content "Close case"
    expect(cases_show_page).to have_content "Sent to SSCL"

    move_back_to_data_to_be_requested_then_move_to_same_step_agin

    click_on "Close case"

    expect(cases_close_page).to be_displayed
    cases_close_page.fill_in_date_responded(offender_sar_case.received_date)
    click_on "Continue"

    expect(cases_closure_outcomes_page).not_to be_displayed

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Closed"
    expect(cases_show_page).to have_content "Send dispatch letter"
    expect(cases_show_page).to have_content "Sent to SSCL"
    # TODO: - pending decision on closure outcomes https://dsdmoj.atlassian.net/browse/CT-2502
    # expect(cases_show_page).to have_content "Was the information held?"
    # expect(cases_show_page).to have_content "Yes"
  end

private

  def move_back_to_data_to_be_requested_then_move_to_same_step_agin
    reason = "move back to ready_to_copy"
    move_back_step(reason)

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Mark as ready to dispatch"
    expect(cases_show_page).to have_content reason

    reason = "move back to vetting_in_progress"
    move_back_step(reason)

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Mark as ready to copy"
    expect(cases_show_page).to have_content reason

    reason = "move back to ready_for_vetting"
    move_back_step(reason)

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Mark as vetting in progress"
    expect(cases_show_page).to have_content reason

    reason = "move back to waiting_for_data"
    move_back_step(reason)

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Mark as ready for vetting"
    expect(cases_show_page).to have_content reason

    reason = "move back to data_to_be_requested"
    move_back_step_without_reason_initially(reason)

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Mark as waiting for data"
    expect(cases_show_page).to have_content reason

    click_on "Mark as waiting for data"
    click_on "Mark as ready for vetting"
    click_on "Mark as vetting in progress"
    click_on "Mark as ready to copy"
    click_on "Mark as ready to dispatch"
  end

  scenario "progressing an offender sar case which is beyond the deadline", js: true do
    cases_show_page.load(id: late_offender_sar_case.id)

    click_on "Mark as waiting for data"
    click_on "Mark as ready for vetting"
    click_on "Mark as vetting in progress"
    click_on "Mark as ready to copy"

    check_available_events_before_recording_reason
    record_reason_of_lateness
    check_available_events_after_recording_reason

    click_on "Mark as ready to dispatch"
  end

  def check_available_events_before_recording_reason
    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Record reason for lateness"
    expect(cases_show_page).not_to have_content "Mark as ready to dispatch"
  end

  def record_reason_of_lateness
    click_on "Record reason for lateness"
    expect(cases_edit_offender_sar_reason_for_lateness_page).to be_displayed
    cases_edit_offender_sar_reason_for_lateness_page.choose_reason(CategoryReference.list_by_category(:reasons_for_lateness).first)
    click_on "Continue"
  end

  def check_available_events_after_recording_reason
    expect(cases_show_page).to be_displayed
    expect(cases_show_page).not_to have_content "Record reason for lateness"
    expect(cases_show_page).to have_content "Mark as ready to dispatch"
    expect(cases_show_page).to have_content "Reason for lateness added"
  end

  def move_back_step(reason)
    click_on "Move case back"

    expect(cases_edit_offender_sar_move_back_page).to be_displayed
    expect(cases_edit_offender_sar_move_back_page).to have_content "reverting case status"
    cases_edit_offender_sar_move_back_page.fill_in_reason(reason)
    click_on "Continue"
  end

  def move_back_step_without_reason_initially(reason)
    click_on "Move case back"

    expect(cases_edit_offender_sar_move_back_page).to be_displayed
    expect(cases_edit_offender_sar_move_back_page).to have_content "reverting case status"
    click_on "Continue"

    expect(cases_edit_offender_sar_move_back_page)
      .to have_content "Please provide the reason for reverting the case back"

    click_on "Back"

    expect(cases_edit_offender_sar_move_back_page)
      .not_to have_content "Please provide the reason for reverting the case back"

    click_on "Move case back"
    cases_edit_offender_sar_move_back_page.fill_in_reason(reason)
    click_on "Continue"
  end
end
