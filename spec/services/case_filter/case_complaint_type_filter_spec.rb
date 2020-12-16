require "rails_helper"

describe CaseFilter::CaseComplaintTypeFilter do

  let(:user)   { find_or_create :branston_user }

  before :all do
    DbHousekeeping.clean

    @offender_sar_complaint_standard  = create :offender_sar_complaint
    @offender_sar_complaint_standard1  = create :offender_sar_complaint

    @offender_sar_complaint_ico  = create :offender_sar_complaint, complaint_type: 'ico_complaint'

    @offender_sar_complaint_litigation  = create :offender_sar_complaint, complaint_type: 'litigation_complaint'
  end

  after(:all) { DbHousekeeping.clean }

  let(:case_complaint_type_filter)  { described_class.new search_query, user, Case::Base }

  describe '.available_case_complaint_types' do
    let(:user) { find_or_create :disclosure_bmt_user }
    let(:search_query)  { create :search_query }
    subject    { case_complaint_type_filter.available_choices.values[0] }

    it { should include 'standard_complaint' => 'Complaint - Standard' }
    it { should include 'ico_complaint' => 'Complaint - ICO' }
    it { should include 'litigation_complaint' => 'Complaint - Litigation' }

  end

  describe '#applied?' do
    subject { case_complaint_type_filter }

    context 'filter_case_complaint_type not present' do
      let(:search_query)      { create :search_query }
      it { should_not be_applied }
    end

    context 'filter_case_complaint_type present' do
      let(:search_query)      { create :search_query,
                                       filter_complaint_ype: ['standard_complaint'] }
      it { should be_applied }
    end

  end

  describe '#call' do

    describe 'filtering for standard complaint cases' do
      let(:search_query)      { create :search_query,
                                       filter_complaint_ype: ['standard_complaint'] }

      it 'returns the correct list of cases' do
        results = case_complaint_type_filter.call
        expect(results).to match_array [
                            @offender_sar_complaint_standard,
                            @offender_sar_complaint_standard1,
                            @offender_sar_complaint_ico,
                            @offender_sar_complaint_litigation
                           ]
      end
    end

    describe 'filtering for ico complaint cases' do
      let(:search_query)      { create :search_query,
                                       filter_complaint_ype: ['ico_complaint'] }

      it 'returns the correct list of cases' do
        results = case_complaint_type_filter.call
        expect(results).to match_array [
                             @offender_sar_complaint_ico,
                           ]
      end
    end

    describe 'filtering for litigation complaint cases' do
      let(:search_query)      { create :search_query,
                                       filter_complaint_ype: ['litigation_complaint'] }

      it 'returns the correct list of cases' do
        results = case_complaint_type_filter.call
        expect(results).to match_array [
                             @offender_sar_complaint_litigation,
                           ]
      end
    end

  end

  describe '#crumbs' do
    context 'no filters selected' do
      let(:search_query)      { create :search_query,
                                       filter_complaint_ype: []}

      it 'returns no crumbs' do
        expect(case_complaint_type_filter.crumbs).to be_empty
      end
    end

    context 'filtering for cases based one type' do
 
      context 'filtering for one complaint type' do
        let(:search_query)      { create :search_query,
                                         filter_complaint_ype: ['standard_complaint'] }

        it 'returns 1 crumb' do
          expect(case_complaint_type_filter.crumbs).to have(1).item
        end

        it 'uses "Complaint - Standard" for the crumb text' do
          expect(case_complaint_type_filter.crumbs[0].first).to eq 'Complaint - Standard'
        end

        describe 'params that will be submitted when clicking on the crumb' do
          subject { case_complaint_type_filter.crumbs[0].second }

          it { should eq 'filter_complaint_ype' => [''],
                         'parent_id'          => search_query.id }
        end
      end

      context 'filtering for more than one type' do
        let(:search_query)      { create :search_query,
                                         filter_case_type: ['ico_complaint', 'litigation_complaint'] }

        it 'returns 2 crumb' do
          expect(case_complaint_type_filter.crumbs).to have(2).item
        end

        it 'uses "FOI - Standard" for the crumb text' do
          expect(case_complaint_type_filter.crumbs[0].first).to eq 'Complaint - ICO + 1'
        end

      end

    end
  end

  describe '.process_params!' do
    it 'processes filter_case_type, sorting and removing blanks' do
      params = { filter_case_type: [
                   '',
                   'standard_complaint',
                   'ico_complaint',
                   'litigation_complaint',
                 ] }
      described_class.process_params!(params)
      expect(params).to eq filter_case_type: [
                             'litigation_complaint',
                             'ico_complaint',
                             'standard_complaint',
                           ]
    end
  end
end
