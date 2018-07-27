require 'rails_helper'

feature "Top level global navigation" do
  let(:responder)                 { create(:responder) }
  let(:manager)                   { create(:manager)  }
  let(:managing_team)             { create :managing_team, managers: [manager] }
  let(:disclosure_specialist)     { create :disclosure_specialist }
  let(:disclosure_specialist_bmt) { create :disclosure_specialist_bmt }
  let(:dacu)                      { find_or_create :team_dacu }

  before do
    responder
    dacu
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
      open_cases_page.load
      expect(open_cases_page).to have_primary_navigation
      expect(open_cases_page.primary_navigation.active_link[:href])
        .to eq '/cases/open'
    end

    scenario "case pages should have nav entries for all pages" do
      open_cases_page.load
      nav_links = open_cases_page.primary_navigation.all_links
      expect(nav_links.count).to eq 6
      expect(nav_links[0]).to have_text('All open cases')
      expect(nav_links[1]).to have_text('My open cases')
      expect(nav_links[2]).to have_text('Closed cases')
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
      expect(nav_links.count).to eq 6
      expect(nav_links[0]).to have_text('New cases')
      expect(nav_links[1]).to have_text('All open cases')
      expect(nav_links[2]).to have_text('My open cases')
      expect(nav_links[3]).to have_text('Closed cases')
      expect(nav_links[4]).to have_text('Search')
      expect(nav_links[5]).to have_text('Settings')
    end

    scenario "open in-time page has nav entries" do
      open_cases_page.load
      expect(open_cases_page.primary_navigation.active_link[:href])
        .to eq '/cases/open'
      nav_links = open_cases_page.primary_navigation.all_links
      expect(nav_links.count).to eq 6
      expect(nav_links[0]).to have_text('New cases')
      expect(nav_links[1]).to have_text('All open cases')
      expect(nav_links[2]).to have_text('My open cases')
      expect(nav_links[3]).to have_text('Closed cases')
      expect(nav_links[4]).to have_text('Search')
      expect(nav_links[5]).to have_text('Settings')
    end
  end

  context 'as a disclosure specialist / bmt' do
    background do
      login_as disclosure_specialist_bmt
    end

    scenario "incoming case pages has nav entries" do
      incoming_cases_page.load
      expect(incoming_cases_page.primary_navigation.active_link[:href])
        .to eq '/cases/incoming'
      nav_links = incoming_cases_page.primary_navigation.all_links
      expect(nav_links.count).to eq 7
      expect(nav_links[0]).to have_text('New cases')
      expect(nav_links[1]).to have_text('All open cases')
      expect(nav_links[2]).to have_text('My open cases')
      expect(nav_links[3]).to have_text('Closed cases')
      expect(nav_links[4]).to have_text('Search')
      expect(nav_links[5]).to have_text('Settings')
      expect(nav_links[6]).to have_text('Performance')
    end

    scenario "open in-time page has nav entries" do
      open_cases_page.load
      expect(open_cases_page.primary_navigation.active_link[:href])
        .to eq '/cases/open'
      nav_links = open_cases_page.primary_navigation.all_links
      expect(nav_links.count).to eq 7
      expect(nav_links[0]).to have_text('New cases')
      expect(nav_links[1]).to have_text('All open cases')
      expect(nav_links[2]).to have_text('My open cases')
      expect(nav_links[3]).to have_text('Closed cases')
      expect(nav_links[4]).to have_text('Search')
      expect(nav_links[5]).to have_text('Settings')
      expect(nav_links[6]).to have_text('Performance')
    end
  end
end
