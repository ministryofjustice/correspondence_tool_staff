require "rails_helper"

feature 'Searching for cases' do
  given(:responder) { find_or_create :branston_user}
  given!(:offender_sar_case)     { create :offender_sar_case }
  given(:manager)   { find_or_create :disclosure_bmt_user }
  given!(:kase)     { create :case_being_drafted, subject: offender_sar_case.subject }

  before do
    kase.update_index
    offender_sar_case.update_index

    login_as searcher
    cases_page.load

    cases_page.primary_navigation.search.click
    expect(cases_search_page).to be_displayed
    expect(cases_search_page).not_to have_notices
    cases_search_page.search_query.set search_term
    cases_search_page.search_button.click
    expect(cases_search_page).to be_displayed
  end

  context 'searching for case number' do
    let(:searcher) { responder }
    let(:search_term) { offender_sar_case.number }

    scenario 'finds offender sar cases by case number' do
      expect(cases_search_page.search_results_count.text).to eq "1 case found"
      expect(cases_search_page.case_list.count).to eq 1
      expect(cases_search_page.case_list.first.number).to have_text offender_sar_case.number
    end
  end

  context 'searching for common text as manager' do
    let(:searcher) { manager }
    let(:search_term) { offender_sar_case.subject }

    scenario 'finds FOI case but not offender sar case' do
      expect(cases_search_page.search_results_count.text).to eq "1 case found"
      expect(cases_search_page.case_list.count).to eq 1
      expect(cases_search_page.case_list.first.number).to have_text kase.number
    end
  end

  context 'searching for common text as branston responder' do
    let(:searcher) { responder }
    let(:search_term) { offender_sar_case.subject }

    scenario 'finds offender_sar_case but not FOI' do
      expect(cases_search_page.search_results_count.text).to eq "1 case found"
      expect(cases_search_page.case_list.count).to eq 1
      expect(cases_search_page.case_list.first.number).to have_text offender_sar_case.number
    end
  end
end
