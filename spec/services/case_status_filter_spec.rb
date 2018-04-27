require "rails_helper"

describe CaseStatusFilter do
  before :all do
    DbHousekeeping.clean
    @setup = StandardSetup.new(only_cases: [
                                 :std_draft_foi,
                                 :std_closed_foi,
                               ])
  end

  after(:all) { DbHousekeeping.clean }

  let(:case_status_filter)  { CaseStatusFilter.new search_query,
                                                   Case::Base }

  describe 'filtering for open cases' do
    let(:search_query)      { create :search_query,
                                     filter_status: ['open'] }

    it 'returns the correct list of cases' do
      results = case_status_filter.call
      expect(results).to match_array [
                           @setup.std_draft_foi,
                         ]
    end
  end

  describe 'filtering for closed cases' do
    let(:search_query)      { create :search_query,
                                     filter_status: ['closed'] }

    it 'returns the correct list of cases' do
      results = case_status_filter.call
      expect(results).to match_array [
                           @setup.std_closed_foi,
                         ]
    end
  end
end
