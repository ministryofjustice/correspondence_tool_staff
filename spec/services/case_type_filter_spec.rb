require "rails_helper"

describe CaseTypeFilter do
  before :all do
    DbHousekeeping.clean
    @setup = StandardSetup.new(only_cases: [
      :std_unassigned_foi,
      :trig_unassigned_foi,
      :std_unassigned_irc,
      :std_unassigned_irt
    ])
  end

  after(:all) { DbHousekeeping.clean }

  let(:case_type_filter)  { CaseTypeFilter.new search_query,
                                               Case::Base }

  describe 'filtering for trigger cases' do
    let(:search_query)      { create :search_query,
                                     filter_sensitivity: ['trigger'] }

    it 'returns the correct list of cases' do
      results = case_type_filter.call
      expect(results).to match_array [
                           @setup.trig_unassigned_foi,
                         ]
    end
  end

  describe 'filtering for non-trigger cases' do
    let(:search_query)      { create :search_query,
                                     filter_sensitivity: ['non-trigger'] }

    it 'returns the correct list of cases' do
      results = case_type_filter.call
      expect(results).to match_array [
                           @setup.std_unassigned_foi,
                           @setup.std_unassigned_irc,
                           @setup.std_unassigned_irt,
                         ]
    end
  end

  describe 'filtering for standard FOI cases' do
    let(:search_query)      { create :search_query,
                                     filter_case_type: ['foi-standard'] }

    it 'returns the correct list of cases' do
      results = case_type_filter.call
      expect(results).to match_array [
                           @setup.trig_unassigned_foi,
                           @setup.std_unassigned_foi,
                         ]
    end
  end

  describe 'filtering for internal review of FOI cases for compliance' do
    let(:search_query)      { create :search_query,
                                     filter_case_type: ['foi-ir-compliance'] }

    it 'returns the correct list of cases' do
      results = case_type_filter.call
      expect(results).to match_array [
                           @setup.std_unassigned_irc,
                         ]
    end
  end

  describe 'filtering for internal review of FOI cases for timeliness' do
    let(:search_query)      { create :search_query,
                                     filter_case_type: ['foi-ir-timeliness'] }

    it 'returns the correct list of cases' do
      results = case_type_filter.call
      expect(results).to match_array [
                           @setup.std_unassigned_irt,
                         ]
    end
  end
end
