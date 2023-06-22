require "rails_helper"

# rubocop:disable RSpec/InstanceVariable, RSpec/BeforeAfterAll
describe CaseFilter::CaseStatusFilter do
  let(:user) { find_or_create :disclosure_specialist_bmt }
  let(:case_status_filter) { described_class.new search_query, user, Case::Base.all }

  before(:all) do
    @setup = StandardSetup.new(only_cases: %i[
      std_draft_foi
      std_closed_foi
    ])
  end

  after(:all) do
    DbHousekeeping.clean(seed: false)
  end

  describe "#applied?" do
    subject { case_status_filter }

    context "when filter_status not present" do
      let(:search_query) { create :search_query }

      it { is_expected.not_to be_applied }
    end

    context "when filter_status present" do
      let(:search_query) do
        create :search_query,
               filter_status: %w[open]
      end

      it { is_expected.to be_applied }
    end
  end

  describe "#call" do
    context "when filter not enabled" do
      let(:search_query) do
        create :search_query,
               filter_status: []
      end

      it "returns all cases" do
        results = case_status_filter.call
        expect(results).to match_array [
          @setup.std_draft_foi,
          @setup.std_closed_foi,
        ]
      end
    end

    context "when filtering for open cases" do
      let(:search_query) do
        create :search_query,
               filter_status: %w[open]
      end

      it "returns the correct list of cases" do
        results = case_status_filter.call
        expect(results).to match_array [
          @setup.std_draft_foi,
        ]
      end
    end

    context "when filtering for closed cases" do
      let(:search_query) do
        create :search_query,
               filter_status: %w[closed]
      end

      it "returns the correct list of cases" do
        results = case_status_filter.call
        expect(results).to match_array [
          @setup.std_closed_foi,
        ]
      end
    end

    context "when filtering for both open and closed cases" do
      let(:search_query) do
        create :search_query,
               filter_status: %w[open closed]
      end

      it "returns the correct list of cases" do
        results = case_status_filter.call
        expect(results).to match_array [
          @setup.std_draft_foi,
          @setup.std_closed_foi,
        ]
      end
    end
  end

  describe "#crumbs" do
    context "when filter not enabled" do
      let(:search_query) do
        create :search_query,
               filter_status: []
      end

      it "returns no crumbs" do
        expect(case_status_filter.crumbs).to be_empty
      end
    end

    context "when filtering for open cases" do
      let(:search_query) do
        create :search_query,
               filter_status: %w[open]
      end

      it "returns a single crumb" do
        expect(case_status_filter.crumbs).to have(1).items
      end

      it 'uses "Open" text for the crumb text' do
        expect(case_status_filter.crumbs[0].first).to eq "Open"
      end

      describe "params that will be submitted when clicking on the crumb" do
        it {
          expect(case_status_filter.crumbs[0].second).to eq "filter_status" => [""],
                                                            "parent_id" => search_query.id
        }
      end
    end

    context "when filtering for closed cases" do
      let(:search_query) do
        create :search_query,
               filter_status: %w[closed]
      end

      it 'uses "Closed" text for the crumb text' do
        expect(case_status_filter.crumbs[0].first).to eq "Closed"
      end
    end

    context "when filtering for both open and closed cases" do
      let(:search_query) do
        create :search_query,
               filter_status: %w[open closed]
      end

      it 'uses "Open + 1 more" text for the crumb text' do
        expect(case_status_filter.crumbs[0].first).to eq "Open + 1 more"
      end
    end
  end

  describe ".process_params!" do
    it "processes filter_status, sorting and removing blanks" do
      params = { filter_status: ["", "open", "closed"] }
      described_class.process_params!(params)
      expect(params).to eq filter_status: %w[closed open]
    end
  end
end
# rubocop:enable RSpec/InstanceVariable, RSpec/BeforeAfterAll
