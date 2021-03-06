require 'rails_helper'

describe CaseFilter::InternalDeadlineFilter do

  let(:user)               { find_or_create :disclosure_specialist_bmt }

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

    let(:filter)  { described_class.new(search_query, :user, Case::Base.all) }

    context 'no internal_deadline present' do
      let(:search_query)      { create :search_query }
      it { should_not be_applied }
    end

    context 'both from and to internal_deadline present' do
      let(:search_query)      { create :search_query,
                                       internal_deadline_from: Date.today,
                                       internal_deadline_to:   Date.today }
      it { should be_applied }
    end

    context 'only internal_deadline_from present' do
      let(:search_query)      { create :search_query,
                                       internal_deadline_from: Date.today }
      it { should_not be_applied }
    end

    context 'only internal_deadline_to present' do
      let(:search_query)      { create :search_query,
                                       internal_deadline_to: Date.today }
      it { should_not be_applied }
    end
  end

  describe '#call' do
    let(:arel)    { Case::Base.all }
    let(:filter)  { described_class.new(search_query, :user, arel) }

    context 'no cases with deadline in date range' do
      let(:search_query) { create :search_query,
                            internal_deadline_from: Date.new(2018, 1, 4),
                            internal_deadline_to: Date.new(2018, 2, 20) }


      it 'returns an empty collection' do
        Timecop.freeze(Time.new(2018, 4, 26,14, 57, 0)) do

          expect(filter.call).to eq []
        end
      end
    end

    context 'case with deadline within date rang' do

      let(:search_query) { create :search_query,
                            internal_deadline_from: Date.new(2018, 3, 25),
                            internal_deadline_to: Date.new(2018, 4, 10) }

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

    context 'no deadline from or to selected' do
      let(:search_query)  { create :search_query,
                                   internal_deadline_from: nil,
                                   internal_deadline_to: nil }

      it 'returns no crumbs' do
        expect(filter.crumbs).to be_empty
      end
    end

    context 'from and to date selected' do
      let(:search_query)  { create :search_query,
                                   internal_deadline_from: Date.new(2017, 12, 4),
                                   internal_deadline_to: Date.new(2017, 12, 25) }

      it 'returns a single crumb' do
        expect(filter.crumbs).to have(1).items
      end

      it 'uses the from and to dates in the crumb text' do
        expect(filter.crumbs[0].first).to eq 'Draft deadline 4 Dec 2017 - 25 Dec 2017'
      end

      describe 'params that will be submitted when clicking on the crumb' do
        subject { filter.crumbs[0].second }

        it { should eq 'internal_deadline_from' => '',
                       'internal_deadline_to' => '',
                       'parent_id'            => search_query.id }
      end
    end
  end

  describe '#process_params!' do
    describe 'when processing internal_deadline_from' do
      it 'converts dates from govuk date fields' do
        params = {
          internal_deadline_from_yyyy: '2018',
          internal_deadline_from_mm:   '05',
          internal_deadline_from_dd:   '27',
        }.with_indifferent_access
        described_class.process_params!(params)
        expect(params[:internal_deadline_from]).to eq Date.new(2018, 5, 27)
      end

      it 'clears out an empty date' do
        params = { internal_deadline_from: '' }.with_indifferent_access
        described_class.process_params!(params)
        expect(params[:internal_deadline_from]).to be_nil
      end
    end

    describe 'when processing internal_deadline_to' do
      it 'converts dates from govuk date fields' do
        params = {
          internal_deadline_to_yyyy: '2018',
          internal_deadline_to_mm:   '05',
          internal_deadline_to_dd:   '27',
        }.with_indifferent_access
        described_class.process_params!(params)
        expect(params[:internal_deadline_to]).to eq Date.new(2018, 5, 27)
      end

      it 'clears out an empty date' do
        params = { internal_deadline_to: '' }.with_indifferent_access
        described_class.process_params!(params)
        expect(params[:internal_deadline_to]).to be nil
      end
    end
  end
end
