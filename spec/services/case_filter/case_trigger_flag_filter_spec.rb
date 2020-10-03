require "rails_helper"

describe CaseFilter::CaseTriggerFlagFilter do

  let(:user)               { find_or_create :disclosure_specialist_bmt }

  before :all do
    DbHousekeeping.clean
    @setup = StandardSetup.new(only_cases: [
                                 :sar_noff_unassigned,
                                 :std_unassigned_foi,
                                 :trig_unassigned_foi,
                                 :std_unassigned_irc,
                                 :std_unassigned_irt,
                                 :ico_foi_unassigned,
                                 :ico_sar_unassigned,
                                 :ot_ico_foi_noff_unassigned,
                                 :ot_ico_sar_noff_unassigned,
                               ])
  end

  after(:all) { DbHousekeeping.clean }

  let(:case_trigger_flag_filter)  { described_class.new search_query, user, Case::Base }

  describe '.available_sensitivities' do
    let(:search_query)      { create :search_query }
    subject { case_trigger_flag_filter.available_choices.values[0] }

    it { should include 'non-trigger' => 'Non-trigger' }
    it { should include 'trigger' => 'Trigger' }
  end

  describe '#applied?' do
    subject { case_trigger_flag_filter }

    context 'filter_sensitivity not present' do
      let(:search_query)      { create :search_query }
      it { should_not be_applied }
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
        results = case_trigger_flag_filter.call
        expect(results).to match_array [
                             @setup.trig_unassigned_foi,
                             @setup.ico_foi_unassigned,
                             @setup.ico_sar_unassigned,
                             @setup.ot_ico_foi_noff_unassigned.original_ico_appeal,
                             @setup.ot_ico_sar_noff_unassigned.original_ico_appeal,
                           ]
      end
    end
  end

  describe '#crumbs' do
    context 'no filters selected' do
      let(:search_query)      { create :search_query,
                                       filter_sensitivity: [] }

      it 'returns no crumbs' do
        expect(case_trigger_flag_filter.crumbs).to be_empty
      end
    end

    context 'filtering for trigger cases' do
      let(:search_query)      { create :search_query,
                                       filter_sensitivity: ['trigger'] }

      it 'returns 1 crumb' do
        expect(case_trigger_flag_filter.crumbs).to have(1).item
      end

      it 'uses "Trigger" for the crumb text' do
        expect(case_trigger_flag_filter.crumbs[0].first).to eq 'Trigger'
      end

      describe 'params that will be submitted when clicking on the crumb' do
        subject { case_trigger_flag_filter.crumbs[0].second }

        it { should eq 'filter_sensitivity' => [''],
                       'parent_id'          => search_query.id }
      end

      context 'filtering for non-trigger cases' do
        let(:search_query)      { create :search_query,
                                         filter_sensitivity: ['non-trigger'] }

        it 'uses "Trigger" for the crumb text' do
          expect(case_trigger_flag_filter.crumbs[0].first).to eq 'Non-trigger'
        end
      end

      context 'filtering for Trigger and FOI Standard cases' do
        let(:search_query)      { create :search_query,
                                         filter_sensitivity: ['trigger']}

        it 'returns 2 crumbs' do
          expect(case_trigger_flag_filter.crumbs).to have(1).items
        end

        it 'returns a crumb for the Trigger filter' do
          expect(case_trigger_flag_filter.crumbs[0].first).to eq 'Trigger'
        end
      end
    end
  end

  describe '.process_params!' do
    it 'processes filter_sensitivity, sorting and removing blanks' do
      params = { filter_sensitivity: [
                   '',
                   'trigger',
                   'non-trigger',
                 ] }
      described_class.process_params!(params)
      expect(params).to eq filter_sensitivity: [
                          'non-trigger',
                          'trigger',
                        ]
    end
  end
end
