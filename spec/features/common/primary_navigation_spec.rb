require 'rails_helper'

feature "Top level global navigation" do
  let(:responder)       { create(:responder) }
  let(:manager)         { create(:manager)  }
  let(:managing_team)   { create :managing_team, managers: [manager] }
  let(:dacu)            { create :team_dacu }

  before do
    responder
    dacu
    create(:category, :foi)
  end

  scenario "Visiting the login page" do
    login_page.load
    expect(login_page).to have_no_primary_navigation
  end


  context 'As a manager' do
    background do
      login_as manager
    end

    scenario "Home page should have navigation" do
      cases_page.load
      expect(cases_page).to have_primary_navigation
      expect(cases_page.primary_navigation.active_link[:href]).to eq '/cases/open?timeliness=in_time'
    end

  end

end
