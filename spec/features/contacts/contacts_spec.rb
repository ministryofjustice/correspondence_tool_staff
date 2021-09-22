require 'rails_helper'

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
    add_contact_types_reference_data
  end

  before :each do
    find_or_create :team_branston
    login_as manager
    cases_page.load
  end

  scenario 'branston user can view addresses and create a new address' do
    # click_on 'Addresses'
    visit "contacts"
    then_expect_heading_to_read_address_book
    and_expect_contact_details_to_be_present

    click_on 'Add new address'
    and_fill_in_and_submit_new_contact_details
    and_expect_to_see_success_message
    then_expect_new_details_to_be_present
  end

  scenario 'user can edit an existing address' do
    # click_on 'Addresses'
    visit "contacts"
    and_user_can_edit_a_contact
    
    then_expect_to_see_the_edit_success_message
    then_expect_to_see_edited_details_on_the_index_page
  end


  scenario 'user can delete an address' do
    # click_on 'Addresses'
    visit 'contacts'
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
    click_link 'OFFENDER-SAR - Offender Subject Access Request'
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
      contact_type: 'probation'
    }

    contacts_edit_page.edit_contact(details)
    click_on 'Submit'
  end

  def then_expect_heading_to_read_address_book
    expect(contacts_index_page.page_heading.text).to match('Address book')
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

  # rubocop:disable Metrics/MethodLength
  def add_contact_types_reference_data
    CategoryReference.delete_all
    category_references = [
      { 
        category: 'contact_type',
        code: 'prison',
        value: 'Prison',
        display_order: 10
      },
      { 
        category: 'contact_type',
        code: 'probation',
        value: 'Probation centre',
        display_order: 20
      },
      { 
        category: 'contact_type',
        code: 'solicitor',
        value: 'Solicitor',
        display_order: 30
      },
      { 
        category: 'contact_type',
        code: 'branston',
        value: 'Branson',
        display_order: 40
      },
      { 
        category: 'contact_type',
        code: 'hmpps_hq',
        value: 'HMPPS HQ',
        display_order: 50
      },
      { 
        category: 'contact_type',
        code: 'hmcts',
        value: 'HMCTS',
        display_order: 60
      },
      { 
        category: 'contact_type',
        code: 'other',
        value: 'Other',
        display_order: 70
      }
    ]

    category_references.each do |category_reference|
      CategoryReference.create(category_reference)
    end
  end
  # rubocop:enable Metrics/MethodLength

end
