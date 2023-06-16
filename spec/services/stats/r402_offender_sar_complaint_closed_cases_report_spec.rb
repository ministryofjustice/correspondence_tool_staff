require "rails_helper"

module Stats
  describe R402OffenderSarComplaintClosedCasesReport do
    before(:all) { create_report_type(abbr: :r402) }
    after(:all) { DbHousekeeping.clean(seed: true) }

    describe ".title" do
      it "returns correct title" do
        expect(described_class.title).to eq "Closed complaint cases report"
      end
    end

    describe ".description" do
      it "returns correct description" do
        expect(described_class.description)
          .to eq "Entire list of closed complaint cases"
      end
    end

    describe ".etl_handler" do
      it "returns correct etl_handler" do
        expect(described_class.etl_handler)
          .to eq Stats::ETL::OffenderSarComplaintClosedCases
      end
    end

    describe "reporting" do
      before(:all) do
        @period_start = Date.new(2018, 12, 20)
        @period_end = Date.new(2018, 12, 31)
        @user = create :branston_user

        @closed_standard_complaint =
          create :offender_sar_complaint, :closed,
                 identifier: "closed standard offender complaint",
                 received_date: @period_end - 1.hour

        @closed_ico_compliant =
          create :closed_ico_complaint,
                 identifier: "closed ico offender complaint1",
                 received_date: @period_start

        @closed_litgation_complaint =
          create :closed_litigation_complaint,
                 identifier: "closed litigation complaint2",
                 received_date: @period_start

        @closed_sar =
          create :closed_sar,
                 identifier: "closed sar"

        @closed_foi =
          create :closed_case,
                 identifier: "closed foi"

        @report = described_class.new(
          user: @user,
          period_start: @period_start,
          period_end: @period_end,
        )
      end

      describe "#case_scope" do
        it "ignores any selected periods" do
          expected = [
            @closed_standard_complaint.name,
            @closed_ico_compliant.name,
            @closed_litgation_complaint.name,
          ]
          expect(@report.case_scope.map(&:name)).to match_array(expected)
        end
      end

      describe "#run" do
        it "creates a job to generate closed cases" do
          expect {
            @report.run(report_guid: SecureRandom.uuid)
          }.to change {
            ActiveJob::Base.queue_adapter.enqueued_jobs.count
          }.by 1
        end
      end
    end
  end
end
