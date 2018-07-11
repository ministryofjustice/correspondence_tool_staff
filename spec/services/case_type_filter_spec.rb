require "rails_helper"

describe CaseTypeFilter do
  before :all do
    DbHousekeeping.clean
    @setup = StandardSetup.new(only_cases: [
                                 :sar_noff_unassigned,
                                 :std_unassigned_foi,
                                 :trig_unassigned_foi,
                                 :std_unassigned_irc,
                                 :std_unassigned_irt,
                                 :ico_foi_unassigned,
                                 :ico_sar_unassigned
                               ])
  end

  after(:all) { DbHousekeeping.clean }

  let(:case_type_filter)  { CaseTypeFilter.new search_query,
                                               Case::Base }

  describe '.available_case_types' do
    let(:user) { create :disclosure_bmt_user }
    subject    { CaseTypeFilter.available_case_types(user) }

    it { should include 'foi-standard' => 'FOI - Standard' }
    it { should include 'foi-ir-compliance' => 'FOI - Internal review for compliance' }
    it { should include 'foi-ir-timeliness' => 'FOI - Internal review for timeliness' }
    it { should include 'sar-non-offender' => 'SAR - Non-offender' }
    it { should include 'ico-appeal' =>'ICO appeals' }

    context 'for user who is assigned to a team that only handles FOIs' do
      let(:foi)             { find_or_create(:foi_correspondence_type) }
      let(:responding_team) { create(:business_unit, correspondence_types: [foi]) }
      let(:user)            { create(:user, responding_teams: [responding_team]) }
      subject    { CaseTypeFilter.available_case_types(user) }

      it { should include 'foi-standard' => 'FOI - Standard' }
      it { should include 'foi-ir-compliance' => 'FOI - Internal review for compliance' }
      it { should include 'foi-ir-timeliness' => 'FOI - Internal review for timeliness' }
      it { should_not include 'sar-non-offender' => 'SAR - Non-offender' }
      it { should_not include 'ico-appeal' =>'ICO appeals' }
    end
  end

  describe '.available_sensitivities' do
    subject { CaseTypeFilter.available_sensitivities }

    it { should include 'non-trigger' => 'Non-trigger' }
    it { should include 'trigger' => 'Trigger' }
  end

  describe '#applied?' do
    subject { case_type_filter }

    context 'filter_case_type and filter_sensitivity not present' do
      let(:search_query)      { create :search_query }
      it { should_not be_applied }
    end

    context 'filter_case_type present' do
      let(:search_query)      { create :search_query,
                                       filter_case_type: ['foi-standard'] }
      it { should be_applied }
    end

    context 'filter_sensitivity present' do
      let(:search_query)      { create :search_query,
                                       filter_sensitivity: ['trigger'] }
      it { should be_applied }
    end
  end

  describe '#call' do
    describe 'filtering for trigger cases' do
      let(:search_query)      { create :search_query,
                                       filter_sensitivity: ['trigger'] }

      it 'returns the correct list of cases' do
        results = case_type_filter.call
        expect(results).to match_array [
                             @setup.trig_unassigned_foi,
                             @setup.ico_foi_unassigned,
                             @setup.ico_sar_unassigned,
                           ]
      end
    end

    describe 'filtering for non-trigger cases' do
      let(:search_query)      { create :search_query,
                                       filter_sensitivity: ['non-trigger'] }

      it 'returns the correct list of cases' do
        results = case_type_filter.call
        expect(results).to match_array [
                             @setup.sar_noff_unassigned,
                             @setup.std_unassigned_foi,
                             @setup.std_unassigned_irc,
                             @setup.std_unassigned_irt,
                             @setup.ico_foi_unassigned.
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

    describe 'filtering for SAR cases' do
      let(:search_query)      { create :search_query,
                                       filter_case_type: ['sar-non-offender'] }

      it 'returns the correct list of cases' do
        results = case_type_filter.call
        expect(results).to match_array [@setup.sar_noff_unassigned]
      end
    end

    describe 'filtering for ICO cases' do
      let(:search_query)      { create :search_query, filter_case_type: ['ico-appeal']}

      it 'returns ICO FOI and ICO SAR cases' do
        results = case_type_filter.call
        expected_results = [@setup.ico_foi_unassigned, @setup.ico_sar_unassigned]
        expect(results).to match_array expected_results
      end
    end
  end

  describe '#crumbs' do
    context 'no filters selected' do
      let(:search_query)      { create :search_query,
                                       filter_case_type: [],
                                       filter_sensitivity: [] }

      it 'returns no crumbs' do
        expect(case_type_filter.crumbs).to be_empty
      end
    end

    context 'filtering for trigger cases' do
      let(:search_query)      { create :search_query,
                                       filter_sensitivity: ['trigger'] }

      it 'returns 1 crumb' do
        expect(case_type_filter.crumbs).to have(1).item
      end

      it 'uses "Trigger" for the crumb text' do
        expect(case_type_filter.crumbs[0].first).to eq 'Trigger'
      end

      describe 'params that will be submitted when clicking on the crumb' do
        subject { case_type_filter.crumbs[0].second }

        it { should eq 'filter_sensitivity' => [''],
                       'parent_id'          => search_query.id }
      end

      context 'filtering for non-trigger cases' do
        let(:search_query)      { create :search_query,
                                         filter_sensitivity: ['non-trigger'] }

        it 'uses "Trigger" for the crumb text' do
          expect(case_type_filter.crumbs[0].first).to eq 'Non-trigger'
        end
      end

      context 'filtering for standard FOI cases' do
        let(:search_query)      { create :search_query,
                                         filter_case_type: ['foi-standard'] }

        it 'returns 1 crumb' do
          expect(case_type_filter.crumbs).to have(1).item
        end

        it 'uses "FOI - Standard" for the crumb text' do
          expect(case_type_filter.crumbs[0].first).to eq 'FOI - Standard'
        end

        describe 'params that will be submitted when clicking on the crumb' do
          subject { case_type_filter.crumbs[0].second }

          it { should eq 'filter_case_type' => [''],
                         'parent_id'          => search_query.id }
        end
      end

      context 'filtering for internal review of FOI cases for compliance' do
        let(:search_query)      { create :search_query,
                                         filter_case_type: ['foi-ir-compliance'] }

        it 'uses "FOI - IR Compliance" for the crumb text' do
          expect(case_type_filter.crumbs[0].first).to eq 'FOI - Internal review for compliance'
        end
      end

      context 'filtering for internal review of FOI cases for timeliness' do
        let(:search_query)      { create :search_query,
                                         filter_case_type: ['foi-ir-timeliness'] }

        it 'uses "FOI - IR Timeliness" for the crumb text' do
          expect(case_type_filter.crumbs[0].first).to eq 'FOI - Internal review for timeliness'
        end
      end

      context 'filtering for Trigger and FOI Standard cases' do
        let(:search_query)      { create :search_query,
                                         filter_sensitivity: ['trigger'],
                                         filter_case_type: ['foi-standard'] }

        it 'returns 2 crumbs' do
          expect(case_type_filter.crumbs).to have(2).items
        end

        it 'returns a crumb for the FOI Standard filter' do
          expect(case_type_filter.crumbs[0].first).to eq 'FOI - Standard'
        end

        it 'returns a crumb for the Trigger filter' do
          expect(case_type_filter.crumbs[1].first).to eq 'Trigger'
        end
      end
    end
  end

  describe '.process_params!' do
    it 'processes filter_case_type, sorting and removing blanks' do
      params = { filter_case_type: [
                   '',
                   'foi-standard',
                   'foi-ir-compliance',
                   'foi-ir-timeliness',
                 ] }
      CaseTypeFilter.process_params!(params)
      expect(params).to eq filter_case_type: [
                             'foi-ir-compliance',
                             'foi-ir-timeliness',
                             'foi-standard',
                           ]
    end

    it 'processes filter_sensitivity, sorting and removing blanks' do
      params = { filter_sensitivity: [
                   '',
                   'trigger',
                   'non-trigger',
                 ] }
      CaseTypeFilter.process_params!(params)
      expect(params).to eq filter_sensitivity: [
                          'non-trigger',
                          'trigger',
                        ]
    end
  end
end
