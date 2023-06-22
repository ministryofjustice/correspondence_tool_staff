require "rails_helper"

# rubocop:disable RSpec/BeforeAfterAll
describe CaseFilter::CaseComplaintSubtypeFilter do
  let(:user) { find_or_create :branston_user }
  let(:case_complaint_subtype_filter) { described_class.new search_query, user, Case::Base }

  before :all do
    DbHousekeeping.clean

    create :offender_sar_case
    create :foi_case
    create :closed_case
  end

  after(:all) do
    DbHousekeeping.clean(seed: false)
  end

  describe ".available choices" do
    subject    { case_complaint_subtype_filter.available_choices.values[0] }

    let(:user) { find_or_create :disclosure_bmt_user }
    let(:search_query) { create :search_query }

    it "available complaint_subtypes" do
      expect(case_complaint_subtype_filter.available_choices[:filter_complaint_subtype].keys)
        .to match_array Case::SAR::OffenderComplaint.complaint_subtypes.keys
    end
  end

  describe "#applied?" do
    subject { case_complaint_subtype_filter }

    context "when filter_case_complaint_subtype not present" do
      let(:search_query) { create :search_query }

      it { is_expected.not_to be_applied }
    end

    context "when filter_case_complaint_subtype present" do
      let(:search_query) do
        create :search_query,
               filter_complaint_subtype: %w[standard_complaint]
      end

      it { is_expected.to be_applied }
    end
  end

  describe "#call" do
    Case::SAR::OffenderComplaint.complaint_subtypes.each do |complaint_subtype, _|
      describe "filtering for standard complaint cases" do
        let(:search_query) do
          create :search_query,
                 filter_complaint_subtype: [complaint_subtype]
        end

        it "returns the correct list of cases" do
          complaint_case = create(:offender_sar_complaint, complaint_subtype:)
          results = case_complaint_subtype_filter.call
          expect(results).to match_array [complaint_case]
        end
      end
    end
  end

  describe "#crumbs" do
    context "when no filters selected" do
      let(:search_query) do
        create :search_query,
               filter_complaint_subtype: []
      end

      it "returns no crumbs" do
        expect(case_complaint_subtype_filter.crumbs).to be_empty
      end
    end

    context "when filtering for cases" do
      context "and filtering for one complaint subtype" do
        let(:search_query) do
          create :search_query,
                 filter_complaint_subtype: %w[missing_data]
        end

        it "returns 1 crumb" do
          expect(case_complaint_subtype_filter.crumbs).to have(1).item
        end

        it 'uses "Missing data" for the crumb text' do
          expect(case_complaint_subtype_filter.crumbs[0].first).to eq "Missing data"
        end

        describe "params that will be submitted when clicking on the crumb" do
          it {
            expect(case_complaint_subtype_filter.crumbs[0].second).to eq "filter_complaint_subtype" => [""],
                                                                         "parent_id" => search_query.id
          }
        end
      end

      context "and filtering for more than one type" do
        let(:search_query) do
          create :search_query,
                 filter_complaint_subtype: %w[inaccurate_data redacted_data]
        end

        it 'uses "Inaccurate data" for the crumb text' do
          expect(case_complaint_subtype_filter.crumbs[0].first).to eq "Inaccurate data + 1 more"
        end
      end
    end
  end

  describe ".process_params!" do
    it "processes filter_complaint_subtype, sorting and removing blanks" do
      params = { filter_complaint_subtype: [
        "",
        "missing_data",
        "inaccurate_data",
        "timeliness",
      ] }
      described_class.process_params!(params)
      expect(params).to eq filter_complaint_subtype: %w[
        inaccurate_data
        missing_data
        timeliness
      ]
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll
