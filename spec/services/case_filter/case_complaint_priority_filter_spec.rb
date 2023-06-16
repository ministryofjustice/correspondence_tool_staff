require "rails_helper"

describe CaseFilter::CaseComplaintPriorityFilter do
  let(:user) { find_or_create :branston_user }
  let(:case_complaint_prority_filter) { described_class.new search_query, user, Case::Base }

  before :all do
    DbHousekeeping.clean

    @offender_sar_complaint_normal = create :offender_sar_complaint, priority: "normal"
    @offender_sar_complaint_normal1 = create :offender_sar_complaint, priority: "normal"

    @offender_sar_complaint_high = create :offender_sar_complaint, priority: "high"
  end

  after(:all) { DbHousekeeping.clean }

  describe ".available_case_complaint_types" do
    subject    { case_complaint_prority_filter.available_choices.values[0] }

    let(:user) { find_or_create :disclosure_bmt_user }
    let(:search_query) { create :search_query }

    it { is_expected.to include "normal" => "Normal" }
    it { is_expected.to include "high" => "High" }
  end

  describe "#applied?" do
    subject { case_complaint_prority_filter }

    context "filter_case_complaint_type not present" do
      let(:search_query) { create :search_query }

      it { is_expected.not_to be_applied }
    end

    context "filter_case_complaint_type present" do
      let(:search_query) do
        create :search_query,
               filter_complaint_priority: %w[normal]
      end

      it { is_expected.to be_applied }
    end
  end

  describe "#call" do
    describe "filtering for standard complaint cases" do
      let(:search_query) do
        create :search_query,
               filter_complaint_priority: %w[normal]
      end

      it "returns the correct list of cases" do
        results = case_complaint_prority_filter.call
        expect(results).to match_array [
          @offender_sar_complaint_normal,
          @offender_sar_complaint_normal1,
        ]
      end
    end

    describe "filtering for ico complaint cases" do
      let(:search_query) do
        create :search_query,
               filter_complaint_priority: %w[high]
      end

      it "returns the correct list of cases" do
        results = case_complaint_prority_filter.call
        expect(results).to match_array [
          @offender_sar_complaint_high,
        ]
      end
    end
  end

  describe "#crumbs" do
    context "no filters selected" do
      let(:search_query) do
        create :search_query,
               filter_complaint_priority: []
      end

      it "returns no crumbs" do
        expect(case_complaint_prority_filter.crumbs).to be_empty
      end
    end

    context "filtering for cases" do
      context "filtering for one complaint type" do
        let(:search_query) do
          create :search_query,
                 filter_complaint_priority: %w[normal]
        end

        it "returns 1 crumb" do
          expect(case_complaint_prority_filter.crumbs).to have(1).item
        end

        it 'uses "Normal" for the crumb text' do
          expect(case_complaint_prority_filter.crumbs[0].first).to eq "Normal"
        end

        describe "params that will be submitted when clicking on the crumb" do
          subject { case_complaint_prority_filter.crumbs[0].second }

          it {
            expect(subject).to eq "filter_complaint_priority" => [""],
                                  "parent_id" => search_query.id
          }
        end
      end

      context "filtering for more than one type" do
        let(:search_query) do
          create :search_query,
                 filter_complaint_priority: %w[normal high]
        end

        it 'uses "Normal" for the crumb text' do
          expect(case_complaint_prority_filter.crumbs[0].first).to eq "Normal + 1 more"
        end
      end
    end
  end

  describe ".process_params!" do
    it "processes filter_complaint_priority, sorting and removing blanks" do
      params = { filter_complaint_priority: [
        "",
        "normal",
        "high",
      ] }
      described_class.process_params!(params)
      expect(params).to eq filter_complaint_priority: %w[
        high
        normal
      ]
    end
  end
end
