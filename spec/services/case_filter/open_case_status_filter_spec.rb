require "rails_helper"

# rubocop:disable RSpec/InstanceVariable, RSpec/BeforeAfterAll
describe CaseFilter::OpenCaseStatusFilter do
  let(:user) { find_or_create :disclosure_specialist_bmt }
  let(:open_case_status_filter) { described_class.new search_query, user, Case::Base }

  before(:all) do
    @setup = StandardSetup.new(only_cases: %i[
      std_unassigned_foi
      std_awresp_foi
      std_draft_foi
      std_responded_foi
      std_closed_foi
      trig_unassigned_foi
      trig_awresp_foi
      trig_draft_foi
      trig_pdacu_foi_accepted
      full_ppress_foi
      full_pprivate_foi
      full_awdis_foi
      std_responded_foi
      trig_responded_foi
      full_responded_foi
      std_rejected_sar
      std_closed_irc
    ])
  end

  after(:all) do
    DbHousekeeping.clean(seed: true)
  end

  describe "#applied?" do
    subject { open_case_status_filter }

    context "when filter_open_case_status present" do
      let(:search_query) do
        create :search_query,
               filter_open_case_status: %w[unassigned]
      end

      it { is_expected.to be_applied }
    end

    context "when filter_open_case_status NOT present" do
      let(:search_query) do
        create :search_query,
               filter_open_case_status: []
      end

      it { is_expected.not_to be_applied }
    end
  end

  describe "#call" do
    describe "filtering for unassigned cases" do
      let(:search_query)      do
        create :search_query,
               filter_open_case_status: %w[unassigned]
      end

      it "returns the correct list of cases" do
        results = open_case_status_filter.call
        expect(results).to match_array [
          @setup.std_unassigned_foi,
          @setup.trig_unassigned_foi,
        ]
      end
    end

    describe "filtering for awaiting_responder cases" do
      let(:search_query) do
        create :search_query,
               filter_open_case_status: %w[awaiting_responder]
      end

      it "returns the correct list of cases" do
        results = open_case_status_filter.call
        expect(results).to match_array [
          @setup.std_awresp_foi,
          @setup.trig_awresp_foi,
        ]
      end
    end

    describe "filtering for drafting cases" do
      let(:search_query) do
        create :search_query,
               filter_open_case_status: %w[drafting]
      end

      it "returns the correct list of cases" do
        results = open_case_status_filter.call
        expect(results).to match_array [
          @setup.std_draft_foi,
          @setup.trig_draft_foi,
        ]
      end
    end

    describe "filtering for pending_dacu_clearance cases" do
      let(:search_query) do
        create :search_query,
               filter_open_case_status: %w[pending_dacu_clearance]
      end

      it "returns the correct list of cases" do
        results = open_case_status_filter.call
        expect(results).to match_array [@setup.trig_pdacu_foi_accepted]
      end
    end

    describe "filtering for pending_press_office_clearance cases" do
      let(:search_query) do
        create :search_query,
               filter_open_case_status: %w[pending_press_office_clearance]
      end

      it "returns the correct list of cases" do
        results = open_case_status_filter.call
        expect(results).to match_array [@setup.full_ppress_foi]
      end
    end

    describe "filtering for pending_private_office_clearance cases" do
      let(:search_query) do
        create :search_query,
               filter_open_case_status: %w[pending_private_office_clearance]
      end

      it "returns the correct list of cases" do
        results = open_case_status_filter.call
        expect(results).to match_array [@setup.full_pprivate_foi]
      end
    end

    describe "filtering for awaiting_dispatch cases" do
      let(:search_query) do
        create :search_query,
               filter_open_case_status: %w[awaiting_dispatch]
      end

      it "returns the correct list of cases" do
        results = open_case_status_filter.call
        expect(results).to match_array [@setup.full_awdis_foi]
      end
    end

    describe "filtering for responded cases" do
      let(:search_query) do
        create :search_query,
               filter_open_case_status: %w[responded]
      end

      it "returns the correct list of cases" do
        results = open_case_status_filter.call
        expect(results).to match_array [
          @setup.std_responded_foi,
          @setup.trig_responded_foi,
          @setup.full_responded_foi,
        ]
      end
    end

    describe "filtering for rejected cases" do
      let(:search_query) do
        create :search_query,
               filter_open_case_status: %w[rejected]
      end

      it "returns the correct list of cases" do
        results = open_case_status_filter.call
        expect(results).to match_array [
          @setup.std_rejected_sar,
        ]
      end
    end
  end

  describe "#crumbs" do
    context "when no filters selected" do
      let(:search_query) do
        create :search_query,
               filter_case_type: []
      end

      it "returns no crumbs" do
        expect(open_case_status_filter.crumbs).to be_empty
      end
    end

    context "when filtering for trigger cases" do
      let(:search_query) do
        create :search_query,
               filter_open_case_status: %w[unassigned]
      end

      it "returns 1 crumb" do
        expect(open_case_status_filter.crumbs).to have(1).item
      end

      it 'uses "Trigger" for the crumb text' do
        expect(open_case_status_filter.crumbs[0].first).to eq "Needs reassigning"
      end

      describe "params that will be submitted when clicking on the crumb" do
        it {
          expect(open_case_status_filter.crumbs[0].second).to eq "filter_open_case_status" => [""],
                                                                 "parent_id" => search_query.id
        }
      end
    end
  end

  describe "#available_choices" do
    context "when logged in as a Branston user" do
      let(:user) { find_or_create :branston_user }
      let(:open_case_status_filter) { described_class.new search_query, user, Case::Base }
      let(:search_query) do
        create :search_query
      end

      it "has the rejected key" do
        expect(open_case_status_filter.available_choices[:filter_open_case_status]).to have_key("rejected")
      end

      it "returns the filter list with rejected as 'rejected'" do
        expect(open_case_status_filter.available_choices[:filter_open_case_status]["rejected"]).to eq "Rejected"
      end
    end

    context "when logged in as a London Disclosure user" do
      let(:user) { find_or_create :disclosure_specialist_bmt }
      let(:open_case_status_filter) { described_class.new search_query, user, Case::Base }
      let(:search_query) do
        create :search_query
      end

      it "does not have the rejected key" do
        expect(open_case_status_filter.available_choices[:filter_open_case_status]).not_to have_key("rejected")
      end

      it "returns the filter list with rejected as nil" do
        expect(open_case_status_filter.available_choices[:filter_open_case_status]["Rejected"]).to be_nil
      end
    end
  end

  describe ".process_params!" do
    it "processes filter_open_case_status, sorting and removing blanks" do
      params = { filter_open_case_status: [
        "",
        "unassigned",
        "awaiting_responder",
        "drafting",
        "pending_dacu_clearance",
        "pending_press_office_clearance",
        "pending_private_office_clearance",
        "awaiting_dispatch",
        "responded",
        "rejected",
      ] }
      described_class.process_params!(params)
      expect(params).to eq filter_open_case_status: %w[
        awaiting_dispatch
        awaiting_responder
        drafting
        pending_dacu_clearance
        pending_press_office_clearance
        pending_private_office_clearance
        rejected
        responded
        unassigned
      ]
    end
  end
end
# rubocop:enable RSpec/InstanceVariable, RSpec/BeforeAfterAll
