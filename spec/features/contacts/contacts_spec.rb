require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'category_reference_seeder')

feature 'Contacts address book', js: true do
  given(:manager)         { find_or_create :branston_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }

  given(:foi_manager)     { find_or_create :disclosure_bmt_user }

  given!(:contact) { create(:contact,
                           name: 'HMP halifax',
                           address_line_1: '123 test road',
                           address_line_2: 'little heath',
                           town: 'bakersville',
                           county: 'Mercia',
                           postcode: 'FE2 9JK',
                           contact_type: CategoryReference.find_by(code: 'probation'))
  }

  given!(:contact_2) { create(:contact,
                           name: 'Solicitors LLP',
                           address_line_1: '456 fake street',
                           address_line_2: 'little heath',
                           town: 'bakersville',
                           county: 'Mercia',
                           postcode: 'FL7 0YK',
                           contact_type: CategoryReference.find_by(code: 'solicitor'))
  }

  given!(:contact_3) { create(:contact,
                           name: 'HMP Wellingsville',
                           address_line_1: '789 some lane',
                           address_line_2: 'little heath',
                           town: 'bakersville',
                           county: 'Mercia',
                           postcode: 'TH8 9KO',
                           contact_type: CategoryReference.find_by(code: 'prison'))
  }

  before :all do
    CategoryReferenceSeeder::ContactTypeSeeder.unseed!
    CategoryReferenceSeeder::ContactTypeSeeder.seed!
  end

  before :each do
    find_or_create :team_branston
    login_as manager
    cases_page.load
  end

  scenario 'branston user can view addresses and create a new address' do
    click_on 'Addresses'
    then_expect_heading_to_read_address_book
    and_expect_contact_details_to_be_present

    click_on 'Add new address'
    and_fill_in_and_submit_new_contact_details
    and_expect_to_see_success_message
    then_expect_new_details_to_be_present
  end

  scenario 'user can edit an existing address' do
    click_on 'Addresses'
    and_user_can_edit_a_contact

    then_expect_to_see_the_edit_success_message
    then_expect_to_see_edited_details_on_the_index_page
  end


  scenario 'user can delete an address' do
    click_on 'Addresses'
    and_expect_contact_details_to_be_present
    and_user_deletes_an_address
    then_expect_to_see_delete_success_message
    then_expect_deleted_address_details_not_to_be_visible
  end

  scenario 'address book is not visible to non-branston users' do
    login_as foi_manager
    cases_page.load

    then_address_book_link_is_not_visible
  end

  scenario "addresses can be selected by name from the 'Find an address' dialog" do
    when_i_navigate_to_offender_sar_subject_page
    and_fill_in_subject_details_page

    when_i_open_the_address_dialogue_only_prison_and_probation_addresses_should_load
    and_i_use_the_search_dialog_to_select_an_address
    then_i_expect_the_address_i_searched_for_to_have_been_entered_into_the_form
  end

  scenario "a default relationship type and address can be selected on the requester_details page" do
    when_i_navigate_to_offender_sar_subject_page

    and_fill_in_subject_details_page

    when_i_select_info_is_requested_on_someone_elses_behalf
    then_relationship_to_subject_should_be_defaulted_to_solictor
    and_the_relationship_field_should_not_be_visible
    then_the_find_a_solicitor_button_should_be_visible

    when_i_open_the_address_selection_dialogue
    and_only_solicitor_addressess_are_available
    then_i_am_able_to_select_an_address_from_the_dropown
    and_fill_in_the_other_details

    when_i_contine_i_can_go_back_and_the_solicitor_radio_is_still_checked

    when_i_set_relationship_to_subject_to_other
    then_the_reationship_field_is_shown
    and_i_can_enter_a_relationship_type

    when_i_contine_i_can_go_back_and_the_other_radio_is_still_checked

    when_i_select_info_is_not_requested_on_someone_elses_behalf
    then_the_revealing_panel_is_not_visible

    when_i_select_info_is_requested_on_someone_elses_behalf
    then_the_state_remains_the_same
  end

  scenario "a default relationship type and address can be selected on the recipient_details page" do
    when_i_navigate_to_offender_sar_subject_page

    and_fill_in_subject_details_page

    when_i_select_info_is_not_requested_on_someone_elses_behalf
    and_continue_to_recipient_details_page

    when_i_select_that_the_recipient_is_a_third_party
    then_relationship_to_subject_should_be_defaulted_to_solictor
    and_the_relationship_field_should_not_be_visible
    then_the_find_a_solicitor_button_should_be_visible

    when_i_open_the_address_selection_dialogue
    and_only_solicitor_addressess_are_available
    then_i_am_able_to_select_an_address_from_the_dropown
    and_fill_in_the_other_details

    when_i_contine_i_can_go_back_and_the_solicitor_radio_is_still_checked

    when_i_set_relationship_to_subject_to_other
    then_the_reationship_field_is_shown
    and_i_can_enter_a_relationship_type

    when_i_select_the_data_subject_is_the_recipient
    then_the_revealing_panel_is_not_visible

    when_i_select_that_the_recipient_is_a_third_party
    then_the_state_remains_the_same
  end

  def when_i_contine_i_can_go_back_and_the_other_radio_is_still_checked
    click_on 'Continue'
    click_on 'Back'
    then_the_reationship_field_is_shown
    and_the_other_radio_is_still_checked
    and_the_state_remains_the_same
  end

  def and_the_other_radio_is_still_checked
    result = page.evaluate_script("document.getElementById('offender_sar_is_solicitor_other').checked;")
    expect(result).to be true
  end

  def and_the_state_remains_the_same
    then_the_state_remains_the_same
  end


  def when_i_select_the_data_subject_is_the_recipient
    choose('offender_sar_recipient_subject_recipient', visible: false)
  end

  def when_i_select_that_the_recipient_is_a_third_party
    choose('offender_sar_recipient_third_party_recipient', visible: false)
  end

  def and_continue_to_recipient_details_page
    click_on 'Continue'
  end

  def then_the_state_remains_the_same
    value = page.evaluate_script("document.getElementById('offender_sar_third_party_relationship').value;")
    expect(value).to match('partner')

    expect(page).to_not have_content('Find a solicitor address')
  end

  def when_i_select_info_is_not_requested_on_someone_elses_behalf
    choose('offender_sar_third_party_false', visible: false)
  end

  def then_the_revealing_panel_is_not_visible
    expect(page).to_not have_content('Full name of the representative (optional)')
  end

  def and_i_can_enter_a_relationship_type
    page.execute_script("document.getElementById('offender_sar_third_party_relationship').value = 'partner';")
    value = page.evaluate_script("document.getElementById('offender_sar_third_party_relationship').value;")
    expect(value).to match('partner')
  end

  def then_relationship_to_subject_should_be_defaulted_to_solictor
    result = page.evaluate_script("document.getElementById('offender_sar_is_solicitor_solicitor').checked;")
    expect(result).to be true
  end

  def when_i_set_relationship_to_subject_to_other
    page.execute_script("document.getElementById('offender_sar_is_solicitor_other').click();")
  end

  def then_the_reationship_field_is_shown
    expect(page).to have_content("Please specify relationship to the subject")
  end

  def when_i_contine_i_can_go_back_and_the_solicitor_radio_is_still_checked
    click_on 'Continue'
    click_on 'Back'
    and_the_relationship_field_should_not_be_visible
    then_the_find_a_solicitor_button_should_be_visible
  end

  def and_fill_in_the_other_details
    fill_in 'Full name of the representative (optional)', with: "Joe Bloggs"
    fill_in 'Company name (optional)', with: "Generic company"
  end

  def when_i_select_info_is_requested_on_someone_elses_behalf
    choose('offender_sar_third_party_true', visible: false)
  end

  def then_i_am_able_to_select_an_address_from_the_dropown
    click_button("Use Solicitors LLP")

    selected_address_in_textbox = page.find(:css, '#offender_sar_postal_address').value
    expect(selected_address_in_textbox).to include("456 fake street\nlittle heath")
  end

  def and_the_relationship_field_should_not_be_visible
    expect(page).to_not have_content("Please specify relationship to the subject")
  end

  def and_only_solicitor_addressess_are_available
    expect(page).to have_content("Solicitors LLP\n456 fake street")
    expect(page).to_not have_content("HMP Wellingsville")
  end

  def when_i_open_the_address_selection_dialogue
    click_button("Find a solicitor")
  end

  def then_the_find_a_solicitor_button_should_be_visible
    expect(page).to have_content("Find a solicitor")
  end

  def and_fill_in_subject_details_page_and_continue
    and_fill_in_subject_details_page
  end

  def then_i_expect_the_address_i_searched_for_to_have_been_entered_into_the_form
    expect(cases_new_offender_sar_subject_details_page.subject_address).to have_content(contact.address)
  end

  def when_i_open_the_address_dialogue_only_prison_and_probation_addresses_should_load
    click_link 'Back'
    cases_new_offender_sar_subject_details_page.find_an_address_button.click
    expect(page).to have_content('HMP halifax')
    expect(page).to have_content('HMP Wellingsville')
    expect(page).to_not have_content('Solicitors LLP')
  end

  def and_i_use_the_search_dialog_to_select_an_address
    fill_in 'popup-search', with: "HMP HALIFAX"
    click_on 'Search'
    click_on 'Use HMP halifax'
    click_on 'Continue'
    click_link 'Back'
  end

  def and_fill_in_subject_details_page
    cases_new_offender_sar_subject_details_page.fill_in_case_details
    scroll_to cases_new_offender_sar_subject_details_page.submit_button
    click_on "Continue"
    expect(cases_new_offender_sar_requester_details_page).to be_displayed
  end

  def when_i_navigate_to_offender_sar_subject_page
    cases_page.new_case_button.click
    expect(cases_new_page).to be_displayed
    click_link 'Offender SAR - Offender Subject Access Request'
    expect(cases_new_offender_sar_subject_details_page).to be_displayed
  end

  def then_address_book_link_is_not_visible
    expect(page).not_to have_content('Addresses')
  end

  def then_expect_to_see_delete_success_message
    expect(page).to have_content("Address was successfully destroyed.")
  end

  def and_user_deletes_an_address
    accept_confirm do
      click_on 'Delete', match: :first
    end
  end

  def then_expect_deleted_address_details_not_to_be_visible
    expect(page).not_to have_content('123 test road')
    expect(page).not_to have_content('FE2 9JK')
  end

  def then_expect_to_see_the_edit_success_message
    expect(page).to have_content("Address was successfully updated.")
  end

  def then_expect_to_see_edited_details_on_the_index_page
    expect(page).to have_content("789 another road")
    expect(page).to have_content('AF6 9JO')
  end

  def and_user_can_edit_a_contact
    click_link 'Edit', match: :first
    details = {
      name: 'Granary law',
      address_line_1: '789 another road',
      postcode: 'AF6 9JO',
      data_request_name: 'Sue Jones',
      data_request_name: 'sue.jones@gmail.com',
      contact_type: 'probation'
    }

    contacts_edit_page.edit_contact(details)
    click_on 'Submit'
  end

  def then_expect_heading_to_read_address_book
    expect(contacts_index_page.page_heading.text).to match('Organisation address book')
  end

  def and_expect_contact_details_to_be_present
    expect(page).to have_content('123 test road')
    expect(page).to have_content('FE2 9JK')
  end

  def and_fill_in_and_submit_new_contact_details
    details = {
      name: 'John\'s law',
      address_line_1: '345 some road',
      postcode: 'FG9 5IK',
      data_request_name: 'John Smith',
      data_request_emails: 'john.smith@gmail.com',
      contact_type: 'solicitor'
    }

    contacts_new_page.new_contact(details)
    click_on 'Submit'
  end

  def and_expect_to_see_success_message
    expect(page).to have_content("Contact was successfully created.")
  end

  def then_expect_new_details_to_be_present
    expect(page).to have_content("345 some road")
    expect(page).to have_content('FG9 5IK')
  end
end
