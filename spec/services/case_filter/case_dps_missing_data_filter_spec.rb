require "rails_helper"

describe CaseFilter::CaseDpsMissingDataFilter do
  let(:user) { find_or_create :branston_user }
  let(:case_dps_missing_data_filter) { described_class.new search_query, user, Case::Base }

  describe ".available_case_dps_missing_data_filter" do
    subject    { case_dps_missing_data_filter.available_choices.values[0] }

    let(:user) { find_or_create :disclosure_bmt_user }
    let(:search_query) { create :search_query }

    it { is_expected.to include "dps-missing-data" => "Yes" }
    it { is_expected.to include "not-dps-missing-data" => "No" }
  end

  describe "#applied?" do
    subject { case_dps_missing_data_filter }

    context "when filter_dps_missing_data not present" do
      let(:search_query) { create :search_query }

      it { is_expected.not_to be_applied }
    end

    context "when filter_dps_missing_data present" do
      let(:search_query) do
        create :search_query,
               filter_dps_missing_data: %w[dps-missing-data]
      end

      it { is_expected.to be_applied }
    end
  end

  describe "#call" do
    let!(:offender_sar_standard_one) { create :offender_sar_case }
    let!(:offender_sar_standard_two) { create :offender_sar_case }
    let!(:offender_sar_dps_missing_data_one) { create :offender_sar_case, flag_as_dps_missing_data: true }
    let!(:offender_sar_dps_missing_data_two) { create :offender_sar_case, flag_as_dps_missing_data: true }

    describe "filtering for normal cases" do
      let(:search_query) do
        create :search_query,
               filter_dps_missing_data: %w[not-dps-missing-data]
      end

      it "returns the correct list of cases" do
        results = case_dps_missing_data_filter.call
        expect(results).to match_array [
          offender_sar_standard_one,
          offender_sar_standard_two,
        ]
      end
    end

    describe "filtering for dps missing data cases" do
      let(:search_query) do
        create :search_query,
               filter_dps_missing_data: %w[dps-missing-data]
      end

      it "returns the correct list of cases" do
        results = case_dps_missing_data_filter.call
        expect(results).to match_array [
          offender_sar_dps_missing_data_one,
          offender_sar_dps_missing_data_two,
        ]
      end
    end
  end

  describe "#crumbs" do
    context "when no filters selected" do
      let(:search_query) do
        create :search_query,
               filter_dps_missing_data: []
      end

      it "returns no crumbs" do
        expect(case_dps_missing_data_filter.crumbs).to be_empty
      end
    end

    context "when filtering for cases based on flag of dps missing data" do
      context "and filtering for normal case" do
        let(:search_query) do
          create :search_query,
                 filter_dps_missing_data: %w[not-dps-missing-data]
        end

        it "returns 1 crumb" do
          expect(case_dps_missing_data_filter.crumbs).to have(1).item
        end

        it 'uses "Not dps missing data" for the crumb text' do
          expect(case_dps_missing_data_filter.crumbs[0].first).to eq "No"
        end

        describe "params that will be submitted when clicking on the crumb" do
          it {
            expect(case_dps_missing_data_filter.crumbs[0].second).to eq "filter_dps_missing_data" => [""], "parent_id" => search_query.id
          }
        end
      end

      context "and filtering for normal and dps missing data cases" do
        let(:search_query) do
          create :search_query,
                 filter_dps_missing_data: %w[dps-missing-data not-dps-missing-data]
        end

        it 'uses "Dps missing data" for the crumb text' do
          expect(case_dps_missing_data_filter.crumbs[0].first).to eq "Yes + 1 more"
        end
      end
    end
  end

  describe ".process_params!" do
    it "processes filter_dps_missing_data, sorting and removing blanks" do
      params = { filter_dps_missing_data: [
        "",
        "not-dps-missing-data",
        "dps-missing-data",
      ] }
      described_class.process_params!(params)
      expect(params).to eq filter_dps_missing_data: %w[
        dps-missing-data
        not-dps-missing-data
      ]
    end
  end
end
