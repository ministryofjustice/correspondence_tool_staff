require 'rails_helper'

feature 'edit a specific item of correspondence' do

  background do
    create(:correspondence, name: "Sarah Smith")
    create(:category, :gq)
    login_as create(:user)
    visit "correspondence/#{Correspondence.first.id}"
    click_on "Edit"
  end

  scenario 'changing category' do
    page.find('#correspondence_category_id').select('General enquiry')
    click_on 'Save'
    expect(page).to have_content("Correspondence updated")
    new_category = page.find('div.form-label', text: 'Category').find('+p').text
    expect(new_category).to eq 'General enquiry'
  end

end
