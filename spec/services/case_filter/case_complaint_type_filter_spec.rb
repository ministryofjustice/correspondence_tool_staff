require "rails_helper"

describe CaseFilter::CaseComplaintTypeFilter do
  let(:user) { find_or_create :branston_user }
  let(:case_complaint_type_filter) { described_class.new search_query, user, Case::Base }

  before :all do
    DbHousekeeping.clean

    @offender_sar_complaint_standard = create :offender_sar_complaint
    @offender_sar_complaint_standard1 = create :offender_sar_complaint

    @offender_sar_complaint_ico = create :offender_sar_complaint, complaint_type: "ico_complaint"

    @offender_sar_complaint_litigation = create :offender_sar_complaint, complaint_type: "litigation_complaint"
  end

  after(:all) { DbHousekeeping.clean }

  describe ".available_case_complaint_types" do
    subject    { case_complaint_type_filter.available_choices.values[0] }

    let(:user) { find_or_create :disclosure_bmt_user }
    let(:search_query) { create :search_query }

    it { is_expected.to include "standard_complaint" => "Complaint - Standard" }
    it { is_expected.to include "ico_complaint" => "Complaint - ICO" }
    it { is_expected.to include "litigation_complaint" => "Complaint - Litigation" }
  end

  describe "#applied?" do
    subject { case_complaint_type_filter }

    context "when filter_case_complaint_type not present" do
      let(:search_query) { create :search_query }

      it { is_expected.not_to be_applied }
    end

    context "when filter_case_complaint_type present" do
      let(:search_query) do
        create :search_query,
               filter_complaint_type: %w[standard_complaint]
      end

      it { is_expected.to be_applied }
    end
  end

  describe "#call" do
    describe "filtering for standard complaint cases" do
      let(:search_query) do
        create :search_query,
               filter_complaint_type: %w[standard_complaint]
      end

      it "returns the correct list of cases" do
        results = case_complaint_type_filter.call
        expect(results).to match_array [
          @offender_sar_complaint_standard,
          @offender_sar_complaint_standard1,
        ]
      end
    end

    describe "filtering for ico complaint cases" do
      let(:search_query) do
        create :search_query,
               filter_complaint_type: %w[ico_complaint]
      end

      it "returns the correct list of cases" do
        results = case_complaint_type_filter.call
        expect(results).to match_array [
          @offender_sar_complaint_ico,
        ]
      end
    end

    describe "filtering for litigation complaint cases" do
      let(:search_query) do
        create :search_query,
               filter_complaint_type: %w[litigation_complaint]
      end

      it "returns the correct list of cases" do
        results = case_complaint_type_filter.call
        expect(results).to match_array [
          @offender_sar_complaint_litigation,
        ]
      end
    end
  end

  describe "#crumbs" do
    context "when no filters selected" do
      let(:search_query) do
        create :search_query,
               filter_complaint_type: []
      end

      it "returns no crumbs" do
        expect(case_complaint_type_filter.crumbs).to be_empty
      end
    end

    context "when filtering for cases" do
      context "and filtering for one complaint type" do
        let(:search_query) do
          create :search_query,
                 filter_complaint_type: %w[standard_complaint]
        end

        it "returns 1 crumb" do
          expect(case_complaint_type_filter.crumbs).to have(1).item
        end

        it 'uses "Complaint - Standard" for the crumb text' do
          expect(case_complaint_type_filter.crumbs[0].first).to eq "Complaint - Standard"
        end

        describe "params that will be submitted when clicking on the crumb" do
          subject { case_complaint_type_filter.crumbs[0].second }

          it {
            expect(subject).to eq "filter_complaint_type" => [""],
                                  "parent_id" => search_query.id
          }
        end
      end

      context "and filtering for more than one type" do
        let(:search_query) do
          create :search_query,
                 filter_complaint_type: %w[ico_complaint litigation_complaint]
        end

        it 'uses "Complaint - ICO" for the crumb text' do
          expect(case_complaint_type_filter.crumbs[0].first).to eq "Complaint - ICO + 1 more"
        end
      end
    end
  end

  describe ".process_params!" do
    it "processes filter_complaint_type, sorting and removing blanks" do
      params = { filter_complaint_type: [
        "",
        "standard_complaint",
        "ico_complaint",
        "litigation_complaint",
      ] }
      described_class.process_params!(params)
      expect(params).to eq filter_complaint_type: %w[
        ico_complaint
        litigation_complaint
        standard_complaint
      ]
    end
  end
end
