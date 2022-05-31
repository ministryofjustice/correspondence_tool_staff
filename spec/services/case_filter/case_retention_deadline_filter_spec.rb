require "rails_helper"

describe CaseFilter::CaseRetentionDeadlineFilter do
  before(:all) do
    DbHousekeeping.clean
      @offender_sar_retention_2018 = create(:offender_sar_complaint, :closed, :with_retention_schedule, planned_destruction_date: Time.new(2018, 5, 15))
      @offender_sar_retention_2020 = create(:offender_sar_case, :closed, :with_retention_schedule, planned_destruction_date: Time.new(2020, 5, 15))
  end

  after(:all) do
    DbHousekeeping.clean
  end

  let(:user) { find_or_create(:branston_user) }
  let(:filter) { described_class.new search_query, user, Case::Base.joins(:retention_schedule) }

  describe '#available_choices' do
    let(:search_query) { create :search_query }

    it 'contains the choices for the filter' do
      available_choices = Timecop.freeze(Time.new(2018, 5, 15)) { filter.available_choices }

      expect(
        available_choices
      ).to eq({
        :today => {:name => "Today", :from => "{\"day\":\"15\",\"month\":\"05\",\"year\":\"2018\"}", :to => "{\"day\":\"15\",\"month\":\"05\",\"year\":\"2018\"}"},
        :one_month => {:name => "1 month", :from => "{\"day\":\"15\",\"month\":\"04\",\"year\":\"2018\"}", :to => "{\"day\":\"15\",\"month\":\"05\",\"year\":\"2018\"}"},
        :two_months => {:name => "2 months", :from => "{\"day\":\"15\",\"month\":\"03\",\"year\":\"2018\"}", :to => "{\"day\":\"15\",\"month\":\"05\",\"year\":\"2018\"}"},
        :three_months => {:name => "3 months", :from => "{\"day\":\"15\",\"month\":\"02\",\"year\":\"2018\"}", :to => "{\"day\":\"15\",\"month\":\"05\",\"year\":\"2018\"}"},
        :four_months => {:name => "4 months", :from => "{\"day\":\"15\",\"month\":\"01\",\"year\":\"2018\"}", :to => "{\"day\":\"15\",\"month\":\"05\",\"year\":\"2018\"}"}
      })
    end
  end

  describe '#applied?' do
    subject { filter }

    context 'no planned_destruction_date present' do
      let(:search_query) { create :search_query }
      it { should_not be_applied }
    end

    context 'both from and to planned_destruction_date present' do
      let(:search_query) { create :search_query, planned_destruction_date_from: Date.today, planned_destruction_date_to: Date.today }
      it { should be_applied }
    end

    context 'only planned_destruction_date_from present' do
      let(:search_query) { create :search_query, planned_destruction_date_from: Date.today }
      it { should_not be_applied }
    end

    context 'only planned_destruction_date_to present' do
      let(:search_query) { create :search_query, planned_destruction_date_to: Date.today }
      it { should_not be_applied }
    end
  end

  describe '#call' do
    context 'no cases with deadline in date range' do
      let(:search_query) { create :search_query,
                                  planned_destruction_date_from: Date.new(2017, 12, 4),
                                  planned_destruction_date_to: Date.new(2018, 01, 15) }

      it 'returns an empty collection' do
        expect(filter.call).to eq([])
      end
    end

    context 'there are cases within the deadline' do
      let(:search_query) { create :search_query,
                                  planned_destruction_date_from: Date.new(2018, 01, 01),
                                  planned_destruction_date_to: Date.new(2021, 01, 01) }

      it 'returns all the cases in the range' do
        expect(filter.call).to eq([@offender_sar_retention_2018, @offender_sar_retention_2020])
      end
    end

    context 'there are some cases within the deadline, not all' do
      let(:search_query) { create :search_query,
                                  planned_destruction_date_from: Date.new(2019, 01, 01),
                                  planned_destruction_date_to: Date.new(2021, 01, 01) }

      it 'returns only the cases in the range' do
        expect(filter.call).to eq([@offender_sar_retention_2020])
      end
    end
  end

  describe '#crumbs' do
    context 'filter not enabled' do
      let(:search_query) { create :search_query, planned_destruction_date_from: nil, planned_destruction_date_to: nil }

      it 'returns no crumbs' do
        expect(filter.crumbs).to be_empty
      end
    end

    context 'from and to date selected' do
      let(:search_query)  { create :search_query,
                                   planned_destruction_date_from: Date.new(2017, 12, 4),
                                   planned_destruction_date_to: Date.new(2017, 12, 25) }

      it 'returns a single crumb' do
        expect(filter.crumbs).to have(1).items
      end

      it 'uses the from and to dates in the crumb text' do
        expect(filter.crumbs[0].first).to eq 'Destruction due 4 Dec 2017 - 25 Dec 2017'
      end

      describe 'params that will be submitted when clicking on the crumb' do
        subject { filter.crumbs[0].second }

        it { should eq 'planned_destruction_date_from' => '',
                       'planned_destruction_date_to' => '',
                       'parent_id' => search_query.id }
      end
    end
  end
end
