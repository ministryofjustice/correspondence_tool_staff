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
    let!(:offender_sar_complaint_standard) { create :offender_sar_complaint }
    let!(:offender_sar_complaint_standard1) { create :offender_sar_complaint }
    let!(:offender_sar_complaint_dps_missing_data1) { create :offender_sar_complaint, flag_as_dps_missing_case: true }
    let!(:offender_sar_complaint_dps_missing_data2) { create :offender_sar_complaint, flag_as_dps_missing_case: true }

    describe "filtering for normal complaint cases" do
      let(:search_query) do
        create :search_query,
               filter_dps_missing_data: %w[not-dps-missing-data]
      end

      it "returns the correct list of cases" do
        results = case_hgih_profile_filter.call
        expect(results).to match_array [offender_sar_complaint_standard.original_case,
                                         offender_sar_complaint_standard,
                                         offender_sar_complaint_standard1.original_case,
                                         offender_sar_complaint_standard1,
                                         offender_sar_complaint_dps_missing_data1.original_case,
                                         offender_sar_complaint_dps_missing_data2.original_case,]
      end
    end

    describe "filtering for dps missing data complaint cases" do
      let(:search_query) do
        create :search_query,
               filter_dps_missing_data: %w[dps-missing-data]
      end

      it "returns the correct list of cases" do
        results = case_dps_missing_data_filter.call
        expect(results).to match_array [offender_sar_complaint_dps_missing_data1,
                                         offender_sar_complaint_dps_missing_data2,]
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
      context "and filtering for no dps missing data and dps missing data cases" do
        let(:search_query) do
          create :search_query,
                 filter_dps_missing_data: %w[dps-missing-data not-dps-missing-data]
        end

        it 'uses "Yes" for the crumb text' do
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
