require 'rails_helper'

feature 'Contacts address book', js: true do
  given(:manager)         { find_or_create :branston_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }

  given(:contact) { create(:contact, 
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

    
  end

  scenario 'user can edit an existing address' do
    
  end

  scenario 'user can delete an address' do
    
  end

  scenario 'address book is only visible to branston users' do
    
  end

end
