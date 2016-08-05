require 'rails_helper'

feature 'edit a specific item of correspondence' do

  before do
    create(:correspondence, name: "Sarah Smith")
  end

  scenario 'by correspondent name' do
    login_as create(:user)
    visit '/'
    click_on "View"
    click_on "Edit"
    page.find(:select, text: 'Courts').select('Courts')
    click_on 'Save'
    expect(page).to have_content("Correspondence updated")
  end

end
