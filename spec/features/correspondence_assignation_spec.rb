require 'rails_helper'

feature 'Correspondence can be assigned to a drafter' do

  background do
    create(:correspondence)
    create(:user, email: 'jane_doe@drafters-example.com')
  end

  scenario 'from the edit screen' do
    correspondence = Correspondence.first
    visit "correspondence/#{correspondence.id}/edit"
    page.find(:select, text: 'jane_doe@drafters-example.com').select('jane_doe@drafters-example.com')
    click_button 'Save'
    expect(page).to have_content("assigned to jane_doe@drafters-example.com")
  end

end
