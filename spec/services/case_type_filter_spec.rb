require "rails_helper"

describe CaseTypeFilter do
  before :all do
    DbHousekeeping.clean
    @setup = StandardSetup.new(only_cases: [
      :std_unassigned_foi,
      :trig_unassigned_foi,
      :std_unassigned_irc,
      :std_unassigned_irt
    ])
  end

  after(:all) { DbHousekeeping.clean }

  let(:case_type_filter)  { CaseTypeFilter.new search_query,
                                               Case::Base }

  describe '#call' do
    describe 'filtering for trigger cases' do
      let(:search_query)      { create :search_query,
                                       filter_sensitivity: ['trigger'] }

      it 'returns the correct list of cases' do
        results = case_type_filter.call
        expect(results).to match_array [
                             @setup.trig_unassigned_foi,
                           ]
      end
    end

    describe 'filtering for non-trigger cases' do
      let(:search_query)      { create :search_query,
                                       filter_sensitivity: ['non-trigger'] }

      it 'returns the correct list of cases' do
        results = case_type_filter.call
        expect(results).to match_array [
                             @setup.std_unassigned_foi,
                             @setup.std_unassigned_irc,
                             @setup.std_unassigned_irt,
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

        it 'remove the sensitivity filter' do
          expect(subject).to include 'filter_sensitivity' => ['']
        end

        it 'leaves the other attributes untouched' do
          subject.should include(
                           'search_text'            => 'Winnie the Pooh',
                           'common_exemption_ids'   => [],
                           'exemption_ids'          => [],
                           'filter_assigned_to_ids' => [],
                           'filter_case_type'       => [],
                           'filter_status'          => [],
                           'parent_id'              => search_query.id,
                         )
        end
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

          it 'remove the case type filter' do
            expect(subject).to include 'filter_case_type' => ['']
          end

          it 'leaves the other attributes untouched' do
            subject.should include(
                             'search_text'            => 'Winnie the Pooh',
                             'common_exemption_ids'   => [],
                             'exemption_ids'          => [],
                             'filter_assigned_to_ids' => [],
                             'filter_sensitivity'     => [],
                             'filter_status'          => [],
                             'parent_id'              => search_query.id,
                           )
          end
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
end
