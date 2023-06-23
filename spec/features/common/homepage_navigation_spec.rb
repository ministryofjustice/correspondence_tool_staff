require "rails_helper"

feature "top level global navigation" do
  let(:responder)                 { find_or_create(:foi_responder) }
  let(:manager)                   { create(:manager) }
  let(:managing_team)             { create :managing_team, managers: [manager] }
  let(:disclosure_specialist)     { find_or_create :disclosure_specialist }
  let(:disclosure_specialist_bmt) { find_or_create :disclosure_specialist_bmt }
  let(:dacu)                      { find_or_create :team_dacu }

  before do
    responder
    dacu
  end

  context "when a manager" do
    background do
      login_as manager
    end

    scenario "case pages should have nav entries for all pages" do
      open_cases_page.load
      expect(open_cases_page.homepage_navigation.active_link[:href])
        .to eq "/cases/open"

      nav_links = open_cases_page.homepage_navigation.all_links
      expect(nav_links.count).to eq 3
      expect(nav_links[0]).to have_text("All open cases")
      expect(nav_links[1]).to have_text("My open cases")
      expect(nav_links[2]).to have_text("Closed cases")
    end
  end

  context "when a disclosure specialist" do
    background do
      login_as disclosure_specialist
    end

    scenario "incoming case pages has nav entries" do
      incoming_cases_page.load
      expect(incoming_cases_page.homepage_navigation.active_link[:href])
        .to eq "/cases/incoming"

      nav_links = incoming_cases_page.homepage_navigation.all_links
      has_all_nav_links?(nav_links)
    end

    scenario "open all cases page has nav entries" do
      open_cases_page.load
      expect(open_cases_page.homepage_navigation.active_link[:href])
        .to eq "/cases/open"

      nav_links = open_cases_page.homepage_navigation.all_links
      has_all_nav_links?(nav_links)
    end

    scenario "open my cases page has nav entries" do
      my_open_cases_page.load
      expect(open_cases_page.homepage_navigation.active_link[:href])
        .to eq "/cases/my_open/in_time"

      nav_links = open_cases_page.homepage_navigation.all_links
      has_all_nav_links?(nav_links)
    end

    scenario "open closed cases page has nav entries" do
      closed_cases_page.load
      expect(open_cases_page.homepage_navigation.active_link[:href])
        .to eq "/cases/closed"

      nav_links = open_cases_page.homepage_navigation.all_links
      has_all_nav_links?(nav_links)
    end
  end

  context "when a disclosure specialist bmt" do
    background do
      login_as disclosure_specialist_bmt
    end

    scenario "incoming case pages has nav entries" do
      incoming_cases_page.load
      expect(incoming_cases_page.homepage_navigation.active_link[:href])
        .to eq "/cases/incoming"

      nav_links = incoming_cases_page.homepage_navigation.all_links
      has_all_nav_links?(nav_links)
    end

    scenario "open in-time page has nav entries" do
      open_cases_page.load
      expect(open_cases_page.homepage_navigation.active_link[:href])
        .to eq "/cases/open"

      nav_links = open_cases_page.homepage_navigation.all_links
      has_all_nav_links?(nav_links)
    end
  end

  def has_all_nav_links?(nav_links)
    expect(nav_links.count).to eq 4
    expect(nav_links[0]).to have_text("New cases")
    expect(nav_links[1]).to have_text("All open cases")
    expect(nav_links[2]).to have_text("My open cases")
    expect(nav_links[3]).to have_text("Closed cases")
  end
end
