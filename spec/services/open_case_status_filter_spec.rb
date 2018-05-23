require "rails_helper"

describe OpenCaseStatusFilter do
  before(:all) do
    @setup = StandardSetup.new(only_cases: [
                                 :std_unassigned_foi,
                                 :std_awresp_foi,
                                 :std_draft_foi,
                                 :std_responded_foi,
                                 :std_closed_foi,
                                 :trig_unassigned_foi,
                                 :trig_awresp_foi,
                                 :trig_draft_foi,
                                 :trig_pdacu_foi_accepted,
                                 :full_ppress_foi_accepted,
                                 :full_pprivate_foi_accepted,
                                 :full_awdis_foi,
                                 :std_responded_foi,
                                 :trig_responded_foi,
                                 :full_responded_foi,
                                 :std_closed_irc
                               ])
  end

  after(:all) do
    DbHousekeeping.clean
  end

  let(:open_case_status_filter)  { OpenCaseStatusFilter.new search_query,
                                                            Case::Base }
  describe '#applied?' do
    subject { open_case_status_filter }

    context 'filter_open_case_status present' do
      let(:search_query)      { create :search_query,
                                       filter_open_case_status: ['unassigned'] }
      it { should be_applied }
    end

    context 'filter_open_case_status NOT present' do
      let(:search_query)      { create :search_query,
                                       filter_open_case_status: [] }
      it { should_not be_applied }
    end
  end

  describe '#call' do
    describe 'filtering for unassigned cases' do
      let(:search_query)      { create :search_query,
                                       filter_open_case_status: ['unassigned'] }

      it 'returns the correct list of cases' do
        results = open_case_status_filter.call
        expect(results).to match_array [
                             @setup.std_unassigned_foi,
                             @setup.trig_unassigned_foi,
                           ]
      end
    end

    describe 'filtering for awaiting_responder cases' do
      let(:search_query)      { create :search_query,
                                       filter_open_case_status: ['awaiting_responder'] }

      it 'returns the correct list of cases' do
        results = open_case_status_filter.call
        expect(results).to match_array [
                             @setup.std_awresp_foi,
                             @setup.trig_awresp_foi,
                           ]
      end
    end

    describe 'filtering for drafting cases' do
      let(:search_query)      { create :search_query,
                                       filter_open_case_status: ['drafting'] }

      it 'returns the correct list of cases' do
        results = open_case_status_filter.call
        expect(results).to match_array [
                             @setup.std_draft_foi,
                             @setup.trig_draft_foi,
                           ]
      end
    end

    describe 'filtering for pending_dacu_clearance cases' do
      let(:search_query)      { create :search_query,
                                       filter_open_case_status: ['pending_dacu_clearance'] }

      it 'returns the correct list of cases' do
        results = open_case_status_filter.call
        expect(results).to match_array [@setup.trig_pdacu_foi_accepted]
      end
    end

    describe 'filtering for pending_press_office_clearance cases' do
      let(:search_query)      { create :search_query,
                                       filter_open_case_status: ['pending_press_office_clearance'] }

      it 'returns the correct list of cases' do
        results = open_case_status_filter.call
        expect(results).to match_array [@setup.full_ppress_foi_accepted]
      end
    end

    describe 'filtering for pending_private_office_clearance cases' do
      let(:search_query)      { create :search_query,
                                       filter_open_case_status: ['pending_private_office_clearance'] }

      it 'returns the correct list of cases' do
        results = open_case_status_filter.call
        expect(results).to match_array [@setup.full_pprivate_foi_accepted]
      end
    end

    describe 'filtering for awaiting_dispatch cases' do
      let(:search_query)      { create :search_query,
                                       filter_open_case_status: ['awaiting_dispatch'] }

      it 'returns the correct list of cases' do
        results = open_case_status_filter.call
        expect(results).to match_array [@setup.full_awdis_foi]
      end
    end

    describe 'filtering for responded cases' do
      let(:search_query)      { create :search_query,
                                       filter_open_case_status: ['responded'] }

      it 'returns the correct list of cases' do
        results = open_case_status_filter.call
        expect(results).to match_array [
                             @setup.std_responded_foi,
                             @setup.trig_responded_foi,
                             @setup.full_responded_foi
                           ]
      end
    end
  end

  describe '#crumbs' do
    context 'no filters selected' do
      let(:search_query) { create :search_query,
                                  filter_case_type: [] }

      it 'returns no crumbs' do
        expect(open_case_status_filter.crumbs).to be_empty
      end
    end

    context 'filtering for trigger cases' do
      let(:search_query) { create :search_query,
                                  filter_open_case_status: ['unassigned'] }

      it 'returns 1 crumb' do
        expect(open_case_status_filter.crumbs).to have(1).item
      end

      it 'uses "Trigger" for the crumb text' do
        expect(open_case_status_filter.crumbs[0].first).to eq 'Needs reassigning'
      end

      describe 'params that will be submitted when clicking on the crumb' do
        subject { open_case_status_filter.crumbs[0].second }

        it 'remove the sensitivity filter' do
          expect(subject).to include 'filter_open_case_status' => ['']
        end

        it 'leaves the other attributes untouched' do
          expect(subject).to include(
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
  end
end
