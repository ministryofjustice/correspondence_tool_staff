require 'rails_helper'

feature 'Offender SAR Case editing by a manager' do
  given(:manager)         { find_or_create :branston_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }
  given(:offender_sar_case) { create :offender_sar_case, :third_party, received_date: 2.weeks.ago.to_date }

  background do
    find_or_create :team_branston
    login_as manager
    cases_show_page.load(id: offender_sar_case.id)
  end

  scenario 'editing an offender SAR case' do
    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)

    cases_show_page.offender_sar_subject_details.change_link.click
    expect(cases_edit_offender_sar_subject_details_page).to be_displayed
    cases_edit_offender_sar_subject_details_page.edit_name 'Bob Hope'
    click_on "Continue"
    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)
    expect(cases_show_page).to have_content 'Bob Hope'
    expect(cases_show_page).to have_content 'Case updated'
    expect(cases_show_page).to have_content 'Case details edited'

    cases_show_page.offender_sar_requester_details.change_link.click
    expect(cases_edit_offender_sar_requester_details_page).to be_displayed
    cases_edit_offender_sar_requester_details_page.edit_third_party_name 'Bob Hope Superstar'
    click_on "Continue"
    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)
    expect(cases_show_page).to have_content 'Bob Hope Superstar'
    expect(cases_show_page).to have_content 'Case updated'
    expect(cases_show_page).to have_content 'Case details edited'

    cases_show_page.offender_sar_date_received.change_link.click
    expect(cases_edit_offender_sar_date_received_page).to be_displayed
    cases_edit_offender_sar_date_received_page.edit_received_date 1.week.ago.to_date
    click_on "Continue"
    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)
    expect(cases_show_page).to have_content I18n.l(1.week.ago.to_date, format: :default)
    expect(cases_show_page).to have_content 'Case updated'
    expect(cases_show_page).to have_content 'Case details edited'

    cases_show_page.offender_sar_requested_info.change_link.click
    expect(cases_edit_offender_sar_requested_info_page).to be_displayed
    cases_edit_offender_sar_requested_info_page.edit_message "In a hole in the ground there lived a Hobbit."
    click_on "Continue"
    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)
    expect(cases_show_page).to have_content "In a hole in the ground there lived a Hobbit."
    expect(cases_show_page).to have_content 'Case updated'
    expect(cases_show_page).to have_content 'Case details edited'
  end

  scenario 'user can edit the date a case was closed' do
    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)

    when_i_progress_case_to_a_closed_state
    and_i_add_date_that_the_case_wase_responded_to
    then_the_case_show_page_should_be_displayed 
    when_i_click_the_response_sent_change_link
    and_i_edit_the_date_response_sent
    then_i_expect_the_new_date_to_be_reflected_on_the_case_show_page
  end

  scenario 'user can edit/update exempt and pages for dispatch counts' do
    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)
    when_i_update_the_exempt_pages_count
    then_i_should_see_the_updated_exempt_page_count_on_the_show_page

    when_i_update_the_number_of_final_pages
    then_i_should_see_the_pages_for_dispatch_reflected_on_the_show_page
  end

  def when_i_update_the_exempt_pages_count
    click_on 'Update exempt pages'
    expect(page).to have_content('Update exempt pages')
    fill_in 'offender_sar_number_exempt_pages', with: '1541'
    click_on 'Continue'
  end

  def when_i_update_the_number_of_final_pages
    click_on 'Update final page count'
    expect(page).to have_content('Update final page count')
    fill_in 'offender_sar_number_final_pages', with: '1308'
    click_on 'Continue'
  end

  def then_i_should_see_the_updated_exempt_page_count_on_the_show_page
    expect(page).to have_content('1541')
    expect(page).to have_content('Case updated')
  end

  def then_i_should_see_the_pages_for_dispatch_reflected_on_the_show_page 
    expect(page).to have_content('1308')
    expect(page).to have_content('Case updated')
  end

  def when_i_progress_case_to_a_closed_state
    click_on "Mark as waiting for data"
    click_on "Mark as ready for vetting"
    click_on "Mark as vetting in progress"
    click_on "Mark as ready to copy"
    click_on "Mark as ready to dispatch"
    click_on "Close case"
  end

  def and_i_add_date_that_the_case_wase_responded_to
    cases_close_page.fill_in_date_responded(offender_sar_case.received_date + 10)
    click_on "Continue"
    click_on "Close case"
  end

  def then_the_case_show_page_should_be_displayed
    expect(cases_show_page).to have_content "You've closed this case"
  end

  def when_i_click_the_response_sent_change_link
    cases_show_page.offender_sar_external_deadline.change_link.click
  end

  def and_i_edit_the_date_response_sent
    expect(page).to have_content('Edit case closure details')
    cases_edit_offender_sar_date_responded_page.edit_responded_date(offender_sar_case.received_date + 5)
    cases_edit_offender_sar_date_responded_page.continue_button.click
  end

  def then_i_expect_the_new_date_to_be_reflected_on_the_case_show_page
    expect(cases_show_page).to have_content(I18n.l(offender_sar_case.received_date + 5, format: :default))
  end
end
