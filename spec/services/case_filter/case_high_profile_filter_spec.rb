require "rails_helper"
describe CaseFilter::CaseHighProfileFilter do
  let(:user) { find_or_create :branston_user }
  let(:case_hgih_profile_filter) { described_class.new search_query, user, Case::Base }

  describe ".available_case_high_profile" do
    subject    { case_hgih_profile_filter.available_choices.values[0] }

    let(:user) { find_or_create :disclosure_bmt_user }
    let(:search_query) { create :search_query }

    it { is_expected.to include "high-profile" => "High profile" }
    it { is_expected.to include "not-high-profile" => "Not high profile" }
  end

  describe "#applied?" do
    subject { case_hgih_profile_filter }

    context "when filter_high_profile not present" do
      let(:search_query) { create :search_query }

      it { is_expected.not_to be_applied }
    end

    context "when filter_high_profile present" do
      let(:search_query) do
        create :search_query,
               filter_high_profile: %w[high-profile]
      end

      it { is_expected.to be_applied }
    end
  end

  describe "#call" do
    let!(:offender_sar_complaint_standard) { create :offender_sar_complaint }
    let!(:offender_sar_complaint_standard1) { create :offender_sar_complaint }
    let!(:offender_sar_complaint_high_profile1) { create :offender_sar_complaint, flag_as_high_profile: true }
    let!(:offender_sar_complaint_high_profile2) { create :offender_sar_complaint, flag_as_high_profile: true }

    describe "filtering for normal complaint cases" do
      let(:search_query) do
        create :search_query,
               filter_high_profile: %w[not-high-profile]
      end

      it "returns the correct list of cases" do
        results = case_hgih_profile_filter.call
        expect(results).to match_array [
          offender_sar_complaint_standard.original_case,
          offender_sar_complaint_standard,
          offender_sar_complaint_standard1.original_case,
          offender_sar_complaint_standard1,
          offender_sar_complaint_high_profile1.original_case,
          offender_sar_complaint_high_profile2.original_case,
        ]
      end
    end

    describe "filtering for high profile complaint cases" do
      let(:search_query) do
        create :search_query,
               filter_high_profile: %w[high-profile]
      end

      it "returns the correct list of cases" do
        results = case_hgih_profile_filter.call
        expect(results).to match_array [
          offender_sar_complaint_high_profile1,
          offender_sar_complaint_high_profile2,
        ]
      end
    end
  end

  describe "#crumbs" do
    context "when no filters selected" do
      let(:search_query) do
        create :search_query,
               filter_high_profile: []
      end

      it "returns no crumbs" do
        expect(case_hgih_profile_filter.crumbs).to be_empty
      end
    end

    context "when filtering for cases based on flag of high profile" do
      context "and filtering for normal complaint case" do
        let(:search_query) do
          create :search_query,
                 filter_high_profile: %w[not-high-profile]
        end

        it "returns 1 crumb" do
          expect(case_hgih_profile_filter.crumbs).to have(1).item
        end

        it 'uses "Not high profile" for the crumb text' do
          expect(case_hgih_profile_filter.crumbs[0].first).to eq "Not high profile"
        end

        describe "params that will be submitted when clicking on the crumb" do
          it {
            expect(case_hgih_profile_filter.crumbs[0].second).to eq "filter_high_profile" => [""],
                                                                    "parent_id" => search_query.id
          }
        end
      end

      context "and filtering for normal and high profile cases" do
        let(:search_query) do
          create :search_query,
                 filter_high_profile: %w[high-profile not-high-profile]
        end

        it 'uses "High profile" for the crumb text' do
          expect(case_hgih_profile_filter.crumbs[0].first).to eq "High profile + 1 more"
        end
      end
    end
  end

  describe ".process_params!" do
    it "processes filter_high_profile, sorting and removing blanks" do
      params = { filter_high_profile: [
        "",
        "not-high-profile",
        "high-profile",
      ] }
      described_class.process_params!(params)
      expect(params).to eq filter_high_profile: %w[
        high-profile
        not-high-profile
      ]
    end
  end
end
