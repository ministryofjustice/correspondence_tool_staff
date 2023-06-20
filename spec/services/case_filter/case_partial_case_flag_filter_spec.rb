require "rails_helper"

describe CaseFilter::CasePartialCaseFlagFilter do
  let(:user) { find_or_create :branston_user }
  let(:case_partial_case_flag_filter) { described_class.new search_query, user, Case::Base }

  before :all do
    DbHousekeeping.clean

    @offender_sar_partial_case = create :offender_sar_case, :closed, is_partial_case: true
    @offender_sar_not_partial_case = create :offender_sar_case, :closed, is_partial_case: false
  end

  after(:all) { DbHousekeeping.clean }

  describe ".available_case_high_profile" do
    subject    { case_partial_case_flag_filter.available_choices.values[0] }

    let(:user) { find_or_create :disclosure_bmt_user }
    let(:search_query) { create :search_query }

    it { is_expected.to include "partial-case" => "Is partial case" }
    it { is_expected.to include "not-partial-case" => "Is not partial case" }
  end

  describe "#applied?" do
    subject { case_partial_case_flag_filter }

    context "when filter_partial_case_flag not present" do
      let(:search_query) { create :search_query }

      it { is_expected.not_to be_applied }
    end

    context "when filter_partial_case_flag present" do
      let(:search_query) do
        create :search_query,
               filter_partial_case_flag: %w[partial-case]
      end

      it { is_expected.to be_applied }
    end
  end

  describe "#call" do
    describe "filtering for partial cases" do
      let(:search_query) do
        create :search_query,
               filter_partial_case_flag: %w[partial-case]
      end

      it "returns the correct list of cases" do
        results = case_partial_case_flag_filter.call
        expect(results).to match_array [@offender_sar_partial_case]
      end
    end

    describe "filtering for not partial cases" do
      let(:search_query) do
        create :search_query,
               filter_partial_case_flag: %w[not-partial-case]
      end

      it "returns the correct list of cases" do
        results = case_partial_case_flag_filter.call
        expect(results).to match_array [@offender_sar_not_partial_case]
      end
    end
  end

  describe "#crumbs" do
    context "when no filters selected" do
      let(:search_query) do
        create :search_query,
               filter_partial_case_flag: []
      end

      it "returns no crumbs" do
        expect(case_partial_case_flag_filter.crumbs).to be_empty
      end
    end

    context "when filtering for cases based on flag of high profile" do
      context "and filtering for normal complaint case" do
        let(:search_query) do
          create :search_query,
                 filter_partial_case_flag: %w[not-partial-case]
        end

        it "returns 1 crumb" do
          expect(case_partial_case_flag_filter.crumbs).to have(1).item
        end

        it 'uses "Not partial case" for the crumb text' do
          expect(case_partial_case_flag_filter.crumbs[0].first).to eq "Is not partial case"
        end

        describe "params that will be submitted when clicking on the crumb" do
          subject { case_partial_case_flag_filter.crumbs[0].second }

          it {
            expect(subject).to eq "filter_partial_case_flag" => [""],
                                  "parent_id" => search_query.id
          }
        end
      end

      context "and filtering for partial and non-partial cases" do
        let(:search_query) do
          create :search_query,
                 filter_partial_case_flag: %w[partial-case not-partial-case]
        end

        it 'uses "Is partial case" for the crumb text' do
          expect(case_partial_case_flag_filter.crumbs[0].first).to eq "Is partial case + 1 more"
        end
      end
    end
  end

  describe ".process_params!" do
    it "processes filter_partial_case_flag, sorting and removing blanks" do
      params = { filter_partial_case_flag: [
        "",
        "not-partial-case",
        "partial-case",
      ] }
      described_class.process_params!(params)
      expect(params).to eq filter_partial_case_flag: %w[
        not-partial-case
        partial-case
      ]
    end
  end
end
