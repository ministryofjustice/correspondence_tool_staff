require 'rails_helper'

feature 'edit a specific item of correspondence' do

  before do
    create(:correspondence, name: "Sarah Smith")
  end

  scenario 'by correspondent name' do
    visit '/'
    click_on "Edit"
    expect(page).to have_content("Sarah Smith")
  end

end
