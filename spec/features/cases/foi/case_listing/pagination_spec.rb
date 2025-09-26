require "rails_helper"

# rubocop:disable RSpec/BeforeAfterAll
feature "pagination" do
  background :all do
    @cases = create_list :accepted_case, 30
    @responder = find_or_create :foi_responder
  end

  after(:all) do
    DbHousekeeping.clean(seed: true)
  end

  describe "open cases page" do
    scenario "going to page two" do
      login_as @responder
      visit "/cases/open"

      expect(open_cases_page.case_list.count).to eq 20
      expect(open_cases_page.pagination).to have_next_page_link
      expect(open_cases_page.pagination).to have_page_number_links

      open_cases_page.pagination.next_page_link.click

      expect(open_cases_page).to be_displayed
      expect(open_cases_page.case_list.count).to eq 10
    end
  end

  describe "my open cases page" do
    scenario "going to page two" do
      login_as @responder
      visit "/cases/my_open/in_time"

      expect(my_open_cases_page.tabs[0].tab_link[:href])
        .to eq my_open_filter_path(tab: :in_time)
      expect(my_open_cases_page.tabs[1].tab_link[:href])
        .to eq my_open_filter_path(tab: :late)

      expect(my_open_cases_page.pagination).to have_next_page_link
      my_open_cases_page.pagination.next_page_link.click

      expect(my_open_cases_page.tabs[0].tab_link[:href])
        .to eq my_open_filter_path(tab: :in_time)
      expect(my_open_cases_page.tabs[1].tab_link[:href])
        .to eq my_open_filter_path(tab: :late)
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll
