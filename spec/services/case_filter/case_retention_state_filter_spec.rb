require "rails_helper"

describe CaseFilter::CaseRetentionStateFilter do
  let(:user) { find_or_create(:branston_user) }
  let(:filter) { described_class.new search_query, user, Case::Base.joins(:retention_schedule) }

  describe "#available_choices" do
    let(:search_query) { create :search_query }

    it "contains the choices for the filter" do
      expect(
        filter.available_choices,
      ).to eq({ filter_retention_state: { "not_set" => "Not set", "retain" => "Retain", "review" => "Review", "to_be_anonymised" => "Destroy" } })
    end
  end

  describe "#applied?" do
    subject { filter }

    context "when filter_retention_state not present" do
      let(:search_query) { create :search_query }

      it { is_expected.not_to be_applied }
    end

    context "when filter_retention_state present" do
      let(:search_query) { create :search_query, filter_retention_state: %w[review] }

      it { is_expected.to be_applied }
    end
  end

  describe "#call" do
    let(:offender_sar_complaint) { create(:offender_sar_complaint) }
    let!(:offender_sar_retention_not_set) { create(:offender_sar_case, :closed, :with_retention_schedule) }
    let!(:offender_sar_retention_review) { create(:offender_sar_complaint, :closed, :with_retention_schedule, state: :review) }

    context "when filtering for not_set retention cases" do
      let(:search_query) { create :search_query, filter_retention_state: %w[not_set] }

      it "returns the correct list of cases" do
        results = filter.call
        expect(results.records).to match_array([offender_sar_retention_not_set])
      end
    end

    context "when filtering for more than one state" do
      let(:search_query) { create :search_query, filter_retention_state: %w[not_set review] }

      it "returns the correct list of cases" do
        results = filter.call
        expect(results.records).to match_array([offender_sar_retention_not_set, offender_sar_retention_review])
      end
    end
  end

  describe "#crumbs" do
    context "when filter not enabled" do
      let(:search_query) { create :search_query, filter_retention_state: [] }

      it "returns no crumbs" do
        expect(filter.crumbs).to be_empty
      end
    end

    context "when filtering for one retention state" do
      let(:search_query) { create :search_query, filter_retention_state: %w[not_set] }

      it "returns a single crumb" do
        expect(filter.crumbs).to have(1).items
      end

      it "has the state in the crumb text" do
        expect(filter.crumbs[0].first).to eq("Not set")
      end

      describe "params that will be submitted when clicking on the crumb" do
        subject { filter.crumbs[0].second }

        it { is_expected.to eq("filter_retention_state" => [""], "parent_id" => search_query.id) }
      end
    end

    context "when filtering for more than one state" do
      let(:search_query) { create :search_query, filter_retention_state: %w[not_set review] }

      it 'uses "Not set + 1 more" text for the crumb text' do
        expect(filter.crumbs[0].first).to eq("Not set + 1 more")
      end
    end
  end
end
