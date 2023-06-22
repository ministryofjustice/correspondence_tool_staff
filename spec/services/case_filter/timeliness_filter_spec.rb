require "rails_helper"

# rubocop:disable RSpec/InstanceVariable, RSpec/BeforeAfterAll
describe CaseFilter::TimelinessFilter do
  let(:user) { find_or_create :disclosure_specialist_bmt }
  let(:filter_service) { described_class.new search_query, user, Case::Base.all }

  before(:all) do
    @setup = StandardSetup.new(only_cases: %i[
      std_draft_foi
      std_draft_foi_late
    ])
  end

  after(:all) do
    DbHousekeeping.clean(seed: false)
  end

  describe "#applied?" do
    subject { filter_service }

    context "when filter_timeliness not present" do
      let(:search_query) { create :search_query }

      it { is_expected.not_to be_applied }
    end

    context "when filter_timeliness present" do
      let(:search_query) do
        create :search_query,
               filter_timeliness: %w[late]
      end

      it { is_expected.to be_applied }
    end
  end

  describe "#call" do
    context "when filter not enabled" do
      let(:search_query) do
        create :search_query,
               filter_timeliness: []
      end

      it "returns all cases" do
        results = filter_service.call
        expect(results).to match_array [
          @setup.std_draft_foi,
          @setup.std_draft_foi_late,
        ]
      end
    end

    context "when filtering for in time cases" do
      let(:search_query) do
        create :search_query,
               filter_timeliness: %w[in_time]
      end

      it "returns cases that are in time" do
        results = filter_service.call
        expect(results).to match_array [
          @setup.std_draft_foi,
        ]
      end
    end

    context "when filtering for late cases" do
      let(:search_query) do
        create :search_query,
               filter_timeliness: %w[late]
      end

      it "returns the cases that are late" do
        results = filter_service.call
        expect(results).to match_array [
          @setup.std_draft_foi_late,
        ]
      end
    end

    context "when filtering for both in time and late cases" do
      let(:search_query) do
        create :search_query,
               filter_timeliness: %w[in_time late]
      end

      it "returns all cases" do
        results = filter_service.call
        expect(results).to match_array [
          @setup.std_draft_foi,
          @setup.std_draft_foi_late,
        ]
      end
    end
  end

  describe "#crumbs" do
    context "when filter not enabled" do
      let(:search_query) do
        create :search_query,
               filter_timeliness: []
      end

      it "returns no crumbs" do
        expect(filter_service.crumbs).to be_empty
      end
    end

    context "when filtering for in time cases" do
      let(:search_query) do
        create :search_query,
               filter_timeliness: %w[in_time]
      end

      it "returns a single crumb" do
        expect(filter_service.crumbs).to have(1).items
      end

      it 'uses "In time" text for the crumb text' do
        expect(filter_service.crumbs[0].first).to eq "In time"
      end

      describe "params that will be submitted when clicking on the crumb" do
        it {
          expect(filter_service.crumbs[0].second).to eq "filter_timeliness" => [""],
                                "parent_id" => search_query.id
        }
      end
    end

    context "when filtering for late cases" do
      let(:search_query) do
        create :search_query,
               filter_timeliness: %w[late]
      end

      it 'uses "Late" text for the crumb text' do
        expect(filter_service.crumbs[0].first).to eq "Late"
      end
    end

    context "when filtering for both in time and late cases" do
      let(:search_query) do
        create :search_query,
               filter_timeliness: %w[in_time late]
      end

      it 'uses "In time + 1 more" text for the crumb text' do
        expect(filter_service.crumbs[0].first).to eq "In time + 1 more"
      end
    end
  end

  describe ".process_params!" do
    it "processes filter_timeliness, sorting and removing blanks" do
      params = { filter_timeliness: ["", "late", "in-time"] }
      described_class.process_params!(params)
      expect(params).to eq filter_timeliness: %w[in-time late]
    end
  end
end
# rubocop:enable RSpec/InstanceVariable, RSpec/BeforeAfterAll
