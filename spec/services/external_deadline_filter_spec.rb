require 'rails_helper'

describe ExternalDeadlineFilter do

  before(:all) do
    Timecop.freeze(Time.new(2018, 4, 26,14, 57, 0)) do
      @kase_1 = create :case, received_date: 30.business_days.ago
      @kase_2 = create :case, received_date: 25.business_days.ago
      @kase_3 = create :case, received_date: 100.business_days.ago
    end
  end

  after(:all) { DbHousekeeping.clean }

  describe '#applied?' do
    subject { filter }

    let(:filter)  { ExternalDeadlineFilter.new(search_query, Case::Base.all) }

    context 'no external_deadline present' do
      let(:search_query)      { create :search_query }
      it { should_not be_applied }
    end

    context 'both from and to external_deadline present' do
      let(:search_query)      { create :search_query,
                                       external_deadline_from: Date.today,
                                       external_deadline_to:   Date.today }
      it { should be_applied }
    end

    context 'only external_deadline_from present' do
      let(:search_query)      { create :search_query,
                                       external_deadline_from: Date.today }
      it { should_not be_applied }
    end

    context 'only external_deadline_to present' do
      let(:search_query)      { create :search_query,
                                       external_deadline_to: Date.today }
      it { should_not be_applied }
    end
  end

  describe '#call' do
    let(:arel)    { Case::Base.all }
    let(:filter)  { ExternalDeadlineFilter.new(search_query, arel) }

    context 'no cases with deadline in date range' do
      let(:search_query) { create :search_query,
                            external_deadline_from: Date.new(2017, 12, 4),
                            external_deadline_to: Date.new(2017, 12, 25) }


      it 'returns an empty collection' do
        Timecop.freeze(Time.new(2018, 4, 26,14, 57, 0)) do

          expect(filter.call).to eq []
        end
      end
    end

    context 'case with deadline within date rang' do

      let(:search_query) { create :search_query,
                            external_deadline_from: Date.new(2018, 4, 1),
                            external_deadline_to: Date.new(2018, 4, 25) }

      it 'returns only cases within date range' do
        Timecop.freeze(Time.new(2018, 4, 26,14, 57, 0)) do

          expect(filter.call).to match_array [@kase_1, @kase_2]
        end
      end
    end
  end

  describe '#crumbs' do
    let(:arel)          { Case::Base.all }
    let(:filter)        { described_class.new(search_query, arel) }

    context 'no deadline from or to selected' do
      let(:search_query)  { create :search_query,
                                   external_deadline_from: nil,
                                   external_deadline_to: nil }

      it 'returns no crumbs' do
        expect(filter.crumbs).to be_empty
      end
    end

    context 'from and to date selected' do
      let(:search_query)  { create :search_query,
                                   external_deadline_from: Date.new(2017, 12, 4),
                                   external_deadline_to: Date.new(2017, 12, 25) }

      it 'returns a single crumb' do
        expect(filter.crumbs).to have(1).items
      end

      it 'uses the from and to dates in the crumb text' do
        expect(filter.crumbs[0].first).to eq '4 Dec 2017 - 25 Dec 2017'
      end

      describe 'params that will be submitted when clicking on the crumb' do
        subject { filter.crumbs[0].second }

        it 'remove the external deadline filters' do
          expect(subject).to include 'external_deadline_from' => '',
                                     'external_deadline_to'   => ''
        end

        it 'leaves the other attributes untouched' do
          expect(subject).to include(
                               'search_text'            => 'Winnie the Pooh',
                               'common_exemption_ids'   => [],
                               'exemption_ids'          => [],
                               'filter_assigned_to_ids' => [],
                               'filter_case_type'       => [],
                               'filter_sensitivity'     => [],
                               'filter_status'          => [],
                             )
        end
      end
    end
  end
end
