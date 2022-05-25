require 'rails_helper'

feature 'SAR Internal Review Case creation by a manager' do

  given(:responder)       { find_or_create(:sar_responder) }
  given(:responding_team) { create :responding_team, responders: [responder] }
  given(:manager)         { find_or_create :disclosure_bmt_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }
  given(:approver)        { (find_or_create :team_dacu_disclosure).users.first }

  let(:sar_case) { create(:sar_case) }
  let(:foi_case) { create(:foi_case) }
  let(:subject_name) { sar_case.subject_full_name.downcase }
  let(:case_summary_text) { "IR of #{sar_case.number} - new sar case #{subject_name}" }

  let(:latest_sar_ir_number) { Case::SAR::InternalReview.first.number.to_s }

  background do
    responding_team
    find_or_create :team_dacu_disclosure
    login_as manager
    cases_page.load
  end

  before :all do
    require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')
    CaseClosure::MetadataSeeder.seed!
  end

  after :all do
    CaseClosure::MetadataSeeder.unseed!
  end

  scenario 'creating a SAR internal review case', js: true do
    when_i_start_sar_ir_case_journey
    and_i_try_to_link_an_foi_case
    then_i_shoul_expect_to_see_an_error

    when_i_try_to_link_a_regular_sar_case
    and_test_the_back_link_works
    and_link_a_sar_case
    then_i_should_see_the_linked_sar_case_details_on_the_confirm_page

    when_i_confirm_the_linked_sar_details
    then_i_should_see_the_correct_details_pre_populated_on_the_sar_ir_form

    when_fill_in_the_case_details
    and_the_headings_are_correct
    and_i_submit_the_form
    then_the_case_should_be_successfully_created

    when_i_assign_the_case
    then_i_expect_to_land_on_the_case_show_page
    and_that_the_case_is_a_trigger_case

    when_a_responder_logs_in
    then_they_can_accept_and_clear_the_case

    when_an_approver_logs_in
    then_they_can_take_the_case_on_and_clear_the_response

    when_a_responder_logs_in
    then_they_can_mark_the_case_as_sent

    when_a_manager_logs_in
    they_see_the_option_to_close_the_case
  end

  def they_see_the_option_to_close_the_case
    click_link latest_sar_ir_number
    expect(cases_show_page.actions.close_case).to be_a(Capybara::Node::Element)
  end

  def when_a_manager_logs_in
    login_as manager
    cases_page.load
  end

  def then_they_can_take_the_case_on_and_clear_the_response
    click_link 'New cases'
    click_link 'Take case on'

    expect(page).to have_content(latest_sar_ir_number)
    click_link latest_sar_ir_number

    expect(page).not_to have_content('Close case')

    click_link 'Clear response'
    click_button 'Clear response'
  end

  def then_they_can_mark_the_case_as_sent
    click_link latest_sar_ir_number

    cases_show_page.actions.mark_as_sent.click
    cases_respond_page.fill_in_date_responded(Date.today)
    cases_respond_page.submit_button.click

    expect(page).to have_content("The response has been marked as sent")
  end

  def when_a_responder_logs_in
    login_as responder
    cases_page.load
  end

  def when_an_approver_logs_in 
    login_as approver
    cases_page.load
  end

  def then_they_can_accept_and_clear_the_case
    click_link "#{Case::SAR::InternalReview.first.number}"

    assignments_edit_page.accept_radio.click
    assignments_edit_page.confirm_button.click

    click_link 'Ready for Disclosure clearance'
  end

  def when_i_sign_in_as_a_responder
    login_as responder
    cases_page.load
  end

  def and_that_the_case_is_a_trigger_case
    expect(page).to have_content("SAR Internal Review - compliance\nTrigger")
  end

  def when_i_assign_the_case
    click_link "Responder Business Group"
    click_link "SAR Responding Team"
  end

  def then_i_expect_to_land_on_the_case_show_page
    expect(page).to have_content(case_summary_text)
    expect(page).to have_content("Case assigned to SAR Responding Team")
  end

  def when_i_start_sar_ir_case_journey
    click_link 'Create case', match: :first

    expect(page).to have_content("SAR IR - Subject access request internal review")

    click_link "SAR IR - Subject access request internal review"
  end

  def and_i_try_to_link_an_foi_case
    page = case_new_sar_ir_link_case_page
    expect(page).to have_content("Link case details")

    page.fill_in_original_case_number(foi_case.number)
    page.submit_button.click
  end

  def then_i_shoul_expect_to_see_an_error
    page = case_new_sar_ir_link_case_page
    error_message = "The original case must be a SAR (Subject Access Request) correspondence type" 
    expect(page).to have_content(error_message)
  end

  def when_i_try_to_link_a_regular_sar_case 
    page = case_new_sar_ir_link_case_page
    page.fill_in_original_case_number(sar_case.number)
    page.submit_button.click
  end

  def and_test_the_back_link_works
    case_new_sar_ir_confirm_sar_page.back_link.click
    expect(case_new_sar_ir_link_case_page).to have_content("Link case details")
  end

  def and_link_a_sar_case
    when_i_try_to_link_a_regular_sar_case
  end

  def then_i_should_see_the_linked_sar_case_details_on_the_confirm_page 
    page = case_new_sar_ir_confirm_sar_page
    expect(page).to have_content(sar_case.subject_full_name)
    expect(page).to have_content(sar_case.subject)
    expect(page).to have_content(sar_case.email)
    expect(page).to have_content('Check details of the SAR')
  end

  def when_i_confirm_the_linked_sar_details
    case_new_sar_ir_confirm_sar_page.original_case_number.click
    case_new_sar_ir_confirm_sar_page.submit_button.click
  end

  def then_i_should_see_the_correct_details_pre_populated_on_the_sar_ir_form
    expect(page).to have_content("Add case details")
    expect(page).to have_content("Subject type")
    expect(page).to have_content("Offender")
    expect(page).to have_content("Full name of subject")
    expect(page).to have_content(sar_case.subject_full_name)

    requestor_name = case_new_sar_ir_case_details_page.requestor_full_name.value
    expect(requestor_name).to match(sar_case.name)

    case_summary = case_new_sar_ir_case_details_page.case_summary.value
    expect(case_summary).to match(case_summary_text)

    full_case_details = case_new_sar_ir_case_details_page.full_case_details.value
    expect(full_case_details).to match("")
  end

  def when_fill_in_the_case_details
    page = case_new_sar_ir_case_details_page
    page.compliance_subtype.click
    page.third_party_true.click
    page.fill_in_requestor_name("Joe Bloggs")
    page.fill_in_third_party_relationship("Solicitor")

    page.date_today_link.click

    page.fill_in_full_case_details("Case message")
    page.send_by_post.click
    page.fill_in_postal_address("123, Test road, AB1 3CD")
  end

  def and_the_headings_are_correct
    expect(page).to have_content("Is this information being requested on someone else's behalf?")
    expect(page).to have_content("Case summary")
    expect(page).to have_content("Full case details")
    expect(page).to have_content("Requestor's proof of ID and other documents")
  end

  def and_i_submit_the_form
    case_new_sar_ir_case_details_page.submit_button.click
  end

  def then_the_case_should_be_successfully_created
    expect(page).to have_content("SAR Internal Review - compliance case created")
    expect(page).to have_content("Create case")
    expect(page).to have_content("Assign case")
  end
end
