require "rails_helper"

# rubocop:disable RSpec/BeforeAfterAll
module Stats
  describe R900CasesReport do
    before(:all) { DbHousekeeping.clean(seed: true) }
    after(:all) do
      DbHousekeeping.clean(seed: false)
    end

    describe ".title" do
      it "returns correct title" do
        expect(described_class.title).to eq "Cases report"
      end
    end

    describe ".description" do
      it "returns correct description" do
        expect(described_class.description)
          .to eq "The list of cases within allowed and filtered scope"
      end
    end

    describe "#case_scope" do
      before do
        create_report_type(abbr: :r900)
      end

      before(:all) do
        @sar_1 = create :accepted_sar, identifier: "sar-1"
        @offender_sar_1 = create :offender_sar_case, :waiting_for_data, identifier: "osar-1"

        @offender_sar_2 = create :offender_sar_case, :closed, identifier: "osar-2"

        @sar_2 = create :accepted_sar, identifier: "sar-2"
        @offender_sar_3 = create :offender_sar_case, :data_to_be_requested, identifier: "osar-3"
      end

      it "returns all cases with initial scope of nil" do
        report = described_class.new
        expect(report.case_scope).to match_array([@sar_1, @offender_sar_1, @offender_sar_2, @sar_2, @offender_sar_3])
      end

      it "returns all foi cases with initial scope of only ico_foi being asked" do
        report = described_class.new(case_scope: Case::Base.all.where(type: "Case::SAR::Standard"))
        expect(report.case_scope).to match_array([@sar_1, @sar_2])
      end
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll
