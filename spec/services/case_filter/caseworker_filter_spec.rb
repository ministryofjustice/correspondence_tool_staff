require "rails_helper"

describe CaseFilter::CaseworkerFilter do

  before :all do
    DbHousekeeping.clean
    @responding_team = find_or_create :team_branston
    @user =  @responding_team.responders.first

    @offender_sar_complaint  = create :offender_sar_complaint
    @accepted_complaint_case  = create :accepted_complaint_case, responding_team: @responding_team
  end

  after(:all) { DbHousekeeping.clean }

  let(:caseworker_filter)  { described_class.new search_query, @user, Case::Base }

  describe '.available_caseworker_filter' do
    let(:search_query)  { create :search_query }
    subject    { caseworker_filter.available_choices.values[0] }

    it { should include '0' => I18n.t('filters.filter_caseworker.not_assigned') }
    it { should include @user.id.to_s => @user.full_name }
  end

  describe '#applied?' do
    subject { caseworker_filter }

    context 'caseworker_filter not present' do
      let(:search_query)      { create :search_query }
      it { should_not be_applied }
    end

    context 'caseworker_filter present' do
      let(:search_query)      { create :search_query, filter_caseworker: ['0'] }
      it { should be_applied }
    end

  end

  describe '#call' do

    describe 'filtering for unassigned cases' do
      let(:search_query)      { create :search_query, filter_caseworker: ['0'] }

      it 'returns the unassigned complaint cases ' do
        results = caseworker_filter.call
        expect(results).to match_array [@offender_sar_complaint]
      end
    end

    describe 'filtering for assigned cases' do
      let(:search_query)      { create :search_query, filter_caseworker: [@user.id.to_s] }

      it 'returns the correct list of cases' do
        results = caseworker_filter.call
        expect(results).to match_array [ @accepted_complaint_case ]
      end
    end

    describe 'filtering for all the complaint cases' do
      let(:search_query)      { create :search_query,
                                       filter_caseworker: ['0', @user.id.to_s] }

      it 'returns the correct list of cases' do
        results = caseworker_filter.call
        expect(results).to match_array [ @offender_sar_complaint, @accepted_complaint_case ]
      end
    end

  end

  describe '#crumbs' do
    context 'no filters selected' do
      let(:search_query)      { create :search_query,
                                       filter_caseworker: []}

      it 'returns no crumbs' do
        expect(caseworker_filter.crumbs).to be_empty
      end
    end

    context 'filtering for cases' do
 
      context 'filtering for unassigned cases' do
        let(:search_query)      { create :search_query,
                                         filter_caseworker: ['0'] }

        it 'returns 1 crumb' do
          expect(caseworker_filter.crumbs).to have(1).item
        end

        it "uses for not assigned yet as the crumb text" do
          expect(caseworker_filter.crumbs[0].first).to eq I18n.t('filters.filter_caseworker.not_assigned')
        end

        describe 'params that will be submitted when clicking on the crumb' do
          subject { caseworker_filter.crumbs[0].second }

          it { should eq 'filter_caseworker' => [''],
                         'parent_id'          => search_query.id }
        end
      end

      context 'filtering for more than one type' do
        let(:search_query)      { create :search_query,
                                         filter_caseworker: ['0', @user.id.to_s] }

        it 'Display right content for the crumb text' do
          expect(caseworker_filter.crumbs[0].first).to eq "#{I18n.t('filters.filter_caseworker.not_assigned')} + 1 more"
        end

      end

    end
  end

  describe '.process_params!' do
    it 'processes filter_caseworker, sorting and removing blanks' do
      params = { filter_caseworker: [
                   '',
                   'test',
                   'abc',
                 ] }
      described_class.process_params!(params)
      expect(params).to eq filter_caseworker: [
                             'abc',
                             'test'
                           ]
    end
  end
end
