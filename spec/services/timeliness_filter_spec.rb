require "rails_helper"

describe TimelinessFilter do
  before :all do
    DbHousekeeping.clean
    @setup = StandardSetup.new(only_cases: [
                                 :std_draft_foi,
                                 :std_draft_foi_late,
                               ])
  end

  after(:all) { DbHousekeeping.clean }

  let(:filter_service)  { described_class.new search_query,
                                              Case::Base.all }

  describe '#applied?' do
    subject { filter_service }

    context 'filter_timeliness not present' do
      let(:search_query)      { create :search_query }
      it { should_not be_applied }
    end

    context 'filter_timeliness present' do
      let(:search_query)      { create :search_query,
                                       filter_timeliness: ['late'] }
      it { should be_applied }
    end
  end

  describe '#call' do
    context 'filter not enabled' do
      let(:search_query) { create :search_query,
                                  filter_timeliness: [] }
      it 'returns all cases' do
        results = filter_service.call
        expect(results).to match_array [
                             @setup.std_draft_foi,
                             @setup.std_draft_foi_late,
                           ]
      end
    end

    context 'filtering for in time cases' do
      let(:search_query) { create :search_query,
                                  filter_timeliness: ['in_time'] }

      it 'returns cases that are in time' do
        results = filter_service.call
        expect(results).to match_array [
                             @setup.std_draft_foi,
                           ]
      end
    end

    context 'filtering for late cases' do
      let(:search_query) { create :search_query,
                                  filter_timeliness: ['late'] }

      it 'returns the cases that are late' do
        results = filter_service.call
        expect(results).to match_array [
                             @setup.std_draft_foi_late,
                           ]
      end
    end

    context 'filtering for both in time and late cases' do
      let(:search_query) { create :search_query,
                                  filter_timeliness: ['in_time', 'late'] }

      it 'returns all cases' do
        results = filter_service.call
        expect(results).to match_array [
                             @setup.std_draft_foi,
                             @setup.std_draft_foi_late,
                           ]
      end
    end
  end

  describe '#crumbs' do
    context 'filter not enabled' do
      let(:search_query) { create :search_query,
                                  filter_timeliness: [] }

      it 'returns no crumbs' do
        expect(filter_service.crumbs).to be_empty
      end
    end

    context 'filtering for in time cases' do
      let(:search_query)      { create :search_query,
                                       filter_timeliness: ['in_time'] }

      it 'returns a single crumb' do
        expect(filter_service.crumbs).to have(1).items
      end

      it 'uses "In time" text for the crumb text' do
        expect(filter_service.crumbs[0].first).to eq 'In time'
      end

      describe 'params that will be submitted when clicking on the crumb' do
        subject { filter_service.crumbs[0].second }

        it { should eq 'filter_timeliness' => [''],
                       'parent_id'         => search_query.id }
      end
    end

    context 'filtering for late cases' do
      let(:search_query)      { create :search_query,
                                       filter_timeliness: ['late'] }

      it 'uses "Late" text for the crumb text' do
        expect(filter_service.crumbs[0].first).to eq 'Late'
      end
    end

    context 'filtering for both in time and late cases' do
      let(:search_query)      { create :search_query,
                                       filter_timeliness: ['in_time', 'late'] }

      it 'uses "In time + 1 more" text for the crumb text' do
        expect(filter_service.crumbs[0].first).to eq 'In time + 1 more'
      end
    end
  end

  describe '.process_params!' do
    it 'processes filter_timeliness, sorting and removing blanks' do
      params = { filter_timeliness: ['', 'late', 'in-time'] }
      described_class.process_params!(params)
      expect(params).to eq filter_timeliness: ['in-time', 'late']
    end
  end
end
