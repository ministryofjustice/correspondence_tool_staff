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
                                                   Case::Base.all }

  describe '#call' do
    context 'filter not enabled' do
      let(:search_query)      { create :search_query,
                                       filter_status: [] }
      it 'returns all cases' do
        results = case_status_filter.call
        expect(results).to match_array [
                             @setup.std_draft_foi,
                             @setup.std_closed_foi,
                           ]
      end
    end

    context 'filtering for open cases' do
      let(:search_query)      { create :search_query,
                                       filter_status: ['open'] }

      it 'returns the correct list of cases' do
        results = case_status_filter.call
        expect(results).to match_array [
                             @setup.std_draft_foi,
                           ]
      end
    end

    context 'filtering for closed cases' do
      let(:search_query)      { create :search_query,
                                       filter_status: ['closed'] }

      it 'returns the correct list of cases' do
        results = case_status_filter.call
        expect(results).to match_array [
                             @setup.std_closed_foi,
                           ]
      end
    end

    context 'filtering for both open and closed cases' do
      let(:search_query)      { create :search_query,
                                       filter_status: ['open', 'closed'] }

      it 'returns the correct list of cases' do
        results = case_status_filter.call
        expect(results).to match_array [
                             @setup.std_draft_foi,
                             @setup.std_closed_foi,
                           ]
      end
    end
  end

  describe '#crumbs' do
    context 'filter not enabled' do
      let(:search_query)      { create :search_query,
                                       filter_status: [] }

      it 'returns no crumbs' do
        expect(case_status_filter.crumbs).to be_empty
      end
    end

    context 'filtering for open cases' do
      let(:search_query)      { create :search_query,
                                       filter_status: ['open'] }
      it 'returns a single crumb' do
        expect(case_status_filter.crumbs).to have(1).items
      end

      it 'uses "Open" text for the crumb text' do
        expect(case_status_filter.crumbs[0].first).to eq 'Open'
      end

      describe 'params that will be submitted when clicking on the crumb' do
        subject { case_status_filter.crumbs[0].second }

        it { should include 'search_text'            => "Winnie the Pooh" }
        it { should include 'common_exemption_ids'   => [] }
        it { should include 'filter_assigned_to_ids' => [] }
        it { should include 'filter_case_type'       => [] }
        it { should include 'exemption_ids'          => [] }
        it { should include 'filter_sensitivity'     => [] }
        it { should include 'filter_status'          => [''] }
        it { should include 'parent_id'              => search_query.id }
      end
    end

    context 'filtering for closed cases' do
      let(:search_query)      { create :search_query,
                                       filter_status: ['closed'] }
      it 'uses "Closed" text for the crumb text' do
        expect(case_status_filter.crumbs[0].first).to eq 'Closed'
      end
    end

    context 'filtering for both open and closed cases' do
      let(:search_query)      { create :search_query,
                                       filter_status: ['open', 'closed'] }

      it 'uses "Open + 1 more" text for the crumb text' do
        expect(case_status_filter.crumbs[0].first).to eq 'Open + 1 more'
      end
    end
  end
end
