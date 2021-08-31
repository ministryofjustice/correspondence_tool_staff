require 'rails_helper'

xfeature 'Contacts address book', js: true do
  given(:manager)         { find_or_create :branston_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }

  given(:foi_manager)                     { find_or_create :disclosure_bmt_user }

  given!(:contact) { create(:contact, 
                           name: 'HMP halifax',
                           address_line_1: '123 test road',
                           address_line_2: 'little heath',
                           town: 'bakersville',
                           county: 'Mercia',
                           postcode: 'FE2 9JK',
                           contact_type: ['prison', 'probation', 'solicitor'].sample) 
  }

  background do
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

  def then_address_book_link_is_not_visible
    expect(page).not_to have_content('Addresses')
  end
  
  def then_expect_to_see_delete_success_message
    expect(page).to have_content("Address was successfully destroyed.")
  end
  
  def and_user_deletes_an_address
    accept_confirm do
      click_on 'Delete' 
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
    click_link('Edit')
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

end
