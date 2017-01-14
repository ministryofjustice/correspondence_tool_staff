require 'rails_helper'

feature 'edit a specific item of case' do

  background do
    create(:case, name: "Sarah Smith")
    create(:category, :gq)
    login_as create(:user)
    visit "cases/#{Case.first.id}/edit"
  end

  xscenario 'changing category' do
    page.find('#case_category_id').select('General enquiry')
    click_on 'Save'
    expect(page).to have_content("Case updated")
    new_category = page.find('div.form-label', text: 'Category').find('+p').text
    expect(new_category).to eq 'General enquiry'
  end

end

