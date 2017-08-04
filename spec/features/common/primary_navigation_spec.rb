require 'rails_helper'

feature "Top level global navigation" do
  let(:responder)             { create(:responder) }
  let(:manager)               { create(:manager)  }
  let(:managing_team)         { create :managing_team, managers: [manager] }
  let(:disclosure_specialist) { create :disclosure_specialist }
  let(:dacu)                  { create :team_dacu }

  before do
    responder
    dacu
    create(:category, :foi)
  end

  scenario "Visiting the login page" do
    login_page.load
    expect(login_page).to have_no_primary_navigation
  end


  context 'as a manager' do
    background do
      login_as manager
    end

    scenario "Home page should have navigation" do
      open_cases_page.load(timeliness: 'in_time')
      expect(open_cases_page).to have_primary_navigation
      expect(open_cases_page.primary_navigation.active_link[:href]).to eq '/cases/open?timeliness=in_time'
    end

    scenario "case pages should have nav entries for all pages" do
      open_cases_page.load(timeliness: 'in_time')
      expect(open_cases_page.primary_navigation.active_link[:href])
        .to eq '/cases/open?timeliness=in_time'
      nav_links = open_cases_page.primary_navigation.all_links
      expect(nav_links.count).to eq 4
      expect(nav_links[0]).to have_text('All open cases')
      expect(nav_links[1]).to have_text('My open cases')
      expect(nav_links[2]).to have_text('Closed cases')
    end

    scenario "open in-time page should tabs" do
      open_cases_page.load(timeliness: 'in_time')
      expect(open_cases_page.active_tab.link[:href])
        .to eq '/cases/open?timeliness=in_time'
      expect(open_cases_page.tabs.count).to eq 2
      expect(open_cases_page.tabs[0]).to have_text('In time')
      expect(open_cases_page.tabs[1]).to have_text('Late')
    end
  end

  context 'as a disclosure specialist' do
    background do
      login_as disclosure_specialist
    end

    scenario "incoming case pages has nav entries" do
      incoming_cases_page.load
      expect(incoming_cases_page.primary_navigation.active_link[:href])
        .to eq '/cases/incoming'
      nav_links = incoming_cases_page.primary_navigation.all_links
      expect(nav_links.count).to eq 4
      expect(nav_links[0]).to have_text('New cases')
      expect(nav_links[1]).to have_text('All open cases')
      expect(nav_links[2]).to have_text('My open cases')
      expect(nav_links[3]).to have_text('Closed cases')
    end

    scenario "open in-time page has nav entries" do
      open_cases_page.load(timeliness: 'in_time')
      expect(open_cases_page.primary_navigation.active_link[:href])
        .to eq '/cases/open?timeliness=in_time'
      nav_links = open_cases_page.primary_navigation.all_links
      expect(nav_links.count).to eq 4
      expect(nav_links[0]).to have_text('New cases')
      expect(nav_links[1]).to have_text('All open cases')
      expect(nav_links[2]).to have_text('My open cases')
      expect(nav_links[3]).to have_text('Closed cases')
    end

    scenario "open in-time page has tabs" do
      open_cases_page.load(timeliness: 'in_time')
      expect(open_cases_page.active_tab.link[:href])
        .to eq '/cases/open?timeliness=in_time'
      expect(open_cases_page.tabs.count).to eq 2
      expect(open_cases_page.tabs[0]).to have_text('In time')
      expect(open_cases_page.tabs[1]).to have_text('Late')
    end
  end
end
