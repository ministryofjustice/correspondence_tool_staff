require 'rails_helper'

feature 'search for specific items of correspondence' do

  before do
    create(:correspondence, name: "Sarah Smith")
    create(:correspondence, name: "Jenny Jones")
  end

  scenario 'by correspondent name' do
    visit '/'
    fill_in :search, with: "Jones"
    click_on "Search"
    expect(page).to have_content("Jones")
    expect(page).not_to have_content("Smith")
  end

end
