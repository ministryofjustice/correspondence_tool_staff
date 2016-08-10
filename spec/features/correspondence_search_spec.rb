require 'rails_helper'

feature 'search for specific items of correspondence' do

  before do
    create(:correspondence, name: "Sarah Smith")
    create(:correspondence, name: "Jenny Jones")
    create(:user, email: 'jane_doe@assigner-example.com')
  end

  scenario 'by correspondent name' do
    login_as create(:user)
    visit '/'
    fill_in :search, with: "Jones"
    click_on "Search"
    expect(page).to have_content("Jones")
    expect(page).not_to have_content("Smith")
  end

end
