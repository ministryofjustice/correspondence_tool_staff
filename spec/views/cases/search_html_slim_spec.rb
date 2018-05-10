require 'rails_helper'

def allow_case_policy(policy_name)
  policy = double('Pundit::Policy', policy_name => true)
  allow(view).to receive(:policy).with(:case).and_return(policy)
end

def disallow_case_policy(policy_name)
  policy = double('Pundit::Policy', policy_name => false)
  allow(view).to receive(:policy).with(:case).and_return(policy)
end

describe 'cases/search.html.slim', type: :view do
  let(:closed_case) {create(:closed_case)}


  context 'no search query' do
    before :each do
      assign(:cases,[])
      assign(:query, create(:search_query, search_text: ''))
      assign(:action_url, '/cases/search')
      render
      cases_search_page.load(rendered)
    end

    it 'should show a search field' do
      expect(cases_search_page).to have_search_query
    end

    it 'should not display the filters' do
      expect(cases_search_page).to have_no_filters
    end

    it 'should not display number of results found' do
      expect(cases_search_page).to have_no_search_results_count
      expect(cases_search_page).to have_no_found_no_results_copy
    end

  end

  context 'Users searches for case '
    context 'no results are found' do
      before :each do
        assign(:query, create(:search_query, search_text: 'no search results'))
        assign(:cases,[])
        assign(:action_url, '/cases/search')
        render
        cases_search_page.load(rendered)
      end

      it 'should show a search field' do
        expect(cases_search_page).to have_search_query
      end

      it 'should not display the filters' do
        expect(cases_search_page).to have_no_filters
      end

      it 'should display number of results found' do
        expect(cases_search_page).to have_search_results_count
        expect(cases_search_page).to have_found_no_results_copy
      end
    end

    context 'found some results' do
      before :each do
        create :case
        assign(:query, create(:search_query, search_text: 'some search term'))
        assign(:cases,Case::Base.all.page(1).decorate)
        assign(:action_url, '/cases/search')
        render
        cases_search_page.load(rendered)
      end

      it 'should show a search field' do
        expect(cases_search_page).to have_search_query
      end

      it 'should display the filters' do
        expect(cases_search_page).to have_filters
      end

      it 'should display number of results found' do
        expect(cases_search_page).to have_search_results_count
      end
    end

end
