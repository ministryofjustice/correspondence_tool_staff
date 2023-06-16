require "rails_helper"

feature "searching for SAR cases" do
  given(:manager)   { find_or_create :disclosure_bmt_user }
  given(:responder) { kase.responder }
  given!(:kase)     { create :accepted_sar }

  context "a manager" do
    scenario "searching for a SAR case" do
      login_as manager
      cases_page.load
      cases_page.primary_navigation.search.click
      expect(cases_search_page).to be_displayed
      expect(cases_search_page).not_to have_notices

      kase.update_index
      cases_search_page.search_query.set kase.number
      cases_search_page.search_button.click
      expect(cases_search_page).to be_displayed
      expect(cases_search_page).not_to have_notices
      expect(cases_search_page.search_results_count.text).to eq "1 case found"
      expect(cases_search_page.case_list.count).to eq 1
      expect(cases_search_page.case_list.first.number).to have_text kase.number
    end
  end

  context "a responder" do
    given!(:other_kase) { create :sar_case }

    scenario "searching for a SAR case assigned to my team" do
      login_as responder
      cases_page.load
      cases_page.primary_navigation.search.click
      expect(cases_search_page).to be_displayed
      expect(cases_search_page).not_to have_notices

      kase.update_index
      cases_search_page.search_query.set kase.number
      cases_search_page.search_button.click
      expect(cases_search_page).to be_displayed
      expect(cases_search_page).not_to have_notices
      expect(cases_search_page.search_results_count.text).to eq "1 case found"
      expect(cases_search_page.case_list.count).to eq 1
      expect(cases_search_page.case_list.first.number).to have_text kase.number
    end

    scenario "searching for a SAR case not assigned to my team" do
      login_as responder
      cases_page.load
      cases_page.primary_navigation.search.click
      expect(cases_search_page).to be_displayed
      expect(cases_search_page).not_to have_notices

      kase.update_index
      cases_search_page.search_query.set other_kase.number
      cases_search_page.search_button.click
      expect(cases_search_page).to be_displayed
      expect(cases_search_page).not_to have_notices
      expect(cases_search_page.search_results_count.text).to eq "0 cases found"
      expect(cases_search_page).to have_found_no_results_copy
      expect(cases_search_page.case_list.count).to eq 0
      expect(cases_search_page.case_list).not_to have_text kase.number
    end
  end
end
