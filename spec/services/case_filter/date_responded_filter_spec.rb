require 'rails_helper'

describe CaseFilter::DateRespondedFilter do

  let(:user)               { find_or_create :disclosure_specialist_bmt }

  before(:all) do
    Timecop.freeze(Time.new(2018, 4, 26,14, 57, 0)) do
      @kase_1 = create :case, date_responded: 30.business_days.ago
      @kase_2 = create :case, date_responded: 25.business_days.ago
      @kase_3 = create :case, date_responded: 100.business_days.ago
    end
  end

  after(:all) { DbHousekeeping.clean }

  describe '#applied?' do
    subject { filter }

    let(:filter)  { described_class.new(search_query, :user, Case::Base.all) }

    context 'no date_responded present' do
      let(:search_query)      { create :search_query }
      it { should_not be_applied }
    end

    context 'both from and to date_responded present' do
      let(:search_query)      { create :search_query,
                                       date_responded_from: Date.today,
                                       date_responded_to:   Date.today }
      it { should be_applied }
    end

    context 'only date_responded_from present' do
      let(:search_query)      { create :search_query,
                                       date_responded_from: Date.today }
      it { should_not be_applied }
    end

    context 'only date_responded_to present' do
      let(:search_query)      { create :search_query,
                                       date_responded_to: Date.today }
      it { should_not be_applied }
    end
  end

  describe '#call' do
    let(:arel)    { Case::Base.all }
    let(:filter)  { described_class.new(search_query, :user, arel) }

    context 'no cases with date_responded in date range' do
      let(:search_query) { create :search_query,
                            date_responded_from: Date.new(2017, 12, 4),
                            date_responded_to: Date.new(2017, 12, 25) }


      it 'returns an empty collection' do
        Timecop.freeze(Time.new(2018, 4, 26,14, 57, 0)) do

          expect(filter.call).to eq []
        end
      end
    end

    context 'case with date_responded within date rang' do

      let(:search_query) { create :search_query,
                            date_responded_from: Date.new(2018, 3, 1),
                            date_responded_to: Date.new(2018, 4, 25) }

      it 'returns only cases within date range' do
        Timecop.freeze(Time.new(2018, 4, 26,14, 57, 0)) do

          expect(filter.call).to match_array [@kase_1, @kase_2]
        end
      end
    end
  end

  describe '#crumbs' do
    let(:arel)          { Case::Base.all }
    let(:filter)        { described_class.new(search_query, user, arel) }

    context 'no date_responded from or to selected' do
      let(:search_query)  { create :search_query,
                                   date_responded_from: nil,
                                   date_responded_to: nil }

      it 'returns no crumbs' do
        expect(filter.crumbs).to be_empty
      end
    end

    context 'from and to date selected' do
      let(:search_query)  { create :search_query,
                                   date_responded_from: Date.new(2017, 12, 4),
                                   date_responded_to: Date.new(2017, 12, 25) }

      it 'returns a single crumb' do
        expect(filter.crumbs).to have(1).items
      end

      it 'uses the from and to dates in the crumb text' do
        expect(filter.crumbs[0].first).to eq 'Date responded 4 Dec 2017 - 25 Dec 2017'
      end

      describe 'params that will be submitted when clicking on the crumb' do
        subject { filter.crumbs[0].second }

        it { should eq 'date_responded_from' => '',
                       'date_responded_to' => '',
                       'parent_id'            => search_query.id }
      end
    end
  end

  describe '.process_params!' do
    describe 'when processing date_responded_from' do
      it 'converts dates from govuk date fields' do
        params = {
          date_responded_from_yyyy: '2018',
          date_responded_from_mm:   '05',
          date_responded_from_dd:   '27',
        }.with_indifferent_access
        described_class.process_params!(params)
        expect(params[:date_responded_from]).to eq Date.new(2018, 5, 27)
      end

      it 'clears out an empty date' do
        params = { date_responded_from: '' }.with_indifferent_access
        described_class.process_params!(params)
        expect(params[:date_responded_from]).to be_nil
      end
    end

    describe 'when processing date_responded_to' do
      it 'converts dates from govuk date fields' do
        params = {
          date_responded_to_yyyy: '2018',
          date_responded_to_mm:   '05',
          date_responded_to_dd:   '27',
        }.with_indifferent_access
        described_class.process_params!(params)
        expect(params[:date_responded_to]).to eq Date.new(2018, 5, 27)
      end

      it 'clears out an empty date' do
        params = { date_responded_to: '' }.with_indifferent_access
        described_class.process_params!(params)
        expect(params[:date_responded_to]).to be nil
      end
    end
  end
end
