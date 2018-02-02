require "rails_helper"

feature 'searching for SAR cases' do
  given(:approver)  { create :approver }
  given(:manager)   { create :manager }
  given(:responder) { create :responder }
  given!(:kase)     { create :accepted_sar, responder: responder }

  context 'a manager' do
    scenario 'searching for a SAR case' do
      login_as manager
      cases_page.load
      cases_page.primary_navigation.search.click
      expect(cases_search_page).to be_displayed
      expect(cases_search_page).not_to have_notices

      cases_search_page.search_query.set kase.number
      cases_search_page.search_button.click
      expect(cases_search_page).to be_displayed
      expect(cases_search_page).not_to have_notices
      expect(cases_search_page.case_list.count).to eq 1
      expect(cases_search_page.case_list.first.number).to have_text kase.number
    end
  end

  context 'a responder' do
    given!(:other_kase) { create :sar_case }

    scenario 'searching for a SAR case assigned to my team' do
      login_as responder
      cases_page.load
      cases_page.primary_navigation.search.click
      expect(cases_search_page).to be_displayed
      expect(cases_search_page).not_to have_notices

      cases_search_page.search_query.set kase.number
      cases_search_page.search_button.click
      expect(cases_search_page).to be_displayed
      expect(cases_search_page).not_to have_notices
      expect(cases_search_page.case_list.count).to eq 1
      expect(cases_search_page.case_list.first.number).to have_text kase.number
    end

    scenario 'searching for a SAR case not assigned to my team' do
      login_as responder
      cases_page.load
      cases_page.primary_navigation.search.click
      expect(cases_search_page).to be_displayed
      expect(cases_search_page).not_to have_notices

      cases_search_page.search_query.set other_kase.number
      cases_search_page.search_button.click
      expect(cases_search_page).to be_displayed
      expect(cases_search_page).not_to have_notices
      expect(cases_search_page.case_list.count).to eq 0
      expect(cases_search_page.case_list).not_to have_text kase.number
    end
  end
end
