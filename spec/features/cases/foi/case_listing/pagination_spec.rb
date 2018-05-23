require "rails_helper"

feature 'pagination' do
  background :all do
    @responder = create :responder
    @cases = 30.times.map { create :accepted_case, responder: @responder }
  end

  after :all do
    DbHousekeeping.clean
  end

  context 'open cases page' do
    scenario 'going to page two' do
      login_as @responder
      visit '/cases/open'

      expect(open_cases_page.case_list.count).to eq 20
      expect(open_cases_page.pagination).to have_next_page_link

      open_cases_page.pagination.next_page_link.click

      expect(open_cases_page).to be_displayed
      expect(open_cases_page.case_list.count).to eq 10
    end
  end

  context 'my open cases page' do
    scenario 'going to page two' do
      login_as @responder
      visit '/cases/my_open/in_time'

      expect(my_open_cases_page.tabs[0].tab_link[:href])
        .to eq my_open_cases_path(tab: :in_time)
      expect(my_open_cases_page.tabs[1].tab_link[:href])
        .to eq my_open_cases_path(tab: :late)

      expect(my_open_cases_page.pagination).to have_next_page_link
      my_open_cases_page.pagination.next_page_link.click

      expect(my_open_cases_page.tabs[0].tab_link[:href])
        .to eq my_open_cases_path(tab: :in_time)
      expect(my_open_cases_page.tabs[1].tab_link[:href])
        .to eq my_open_cases_path(tab: :late)
    end
  end
end
