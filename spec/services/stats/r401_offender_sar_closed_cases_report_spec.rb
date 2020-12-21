require 'rails_helper'

module Stats
  describe R401OffenderSarClosedCasesReport do
    after(:all) { DbHousekeeping.clean(seed: true) }

    describe '.title' do
      it 'returns correct title' do
        expect(R401OffenderSarClosedCasesReport.title).to eq 'Closed cases report'
      end
    end

    describe '.description' do
      it 'returns correct description' do
        expect(R401OffenderSarClosedCasesReport.description)
          .to eq 'Entire list of closed cases'
      end
    end

    describe '.etl_handler' do
      it 'returns correct etl_handler' do
        expect(R401OffenderSarClosedCasesReport.etl_handler)
          .to eq Stats::ETL::OffenderSarClosedCases
      end
    end

    describe 'reporting' do
      before(:all) do
        DbHousekeeping.clean(seed: true) 
        create_report_type(abbr: :r401)

        @period_start = Date.new(2018, 12, 20)
        @period_end = Date.new(2018, 12, 31)
        @user = create :branston_user

        @closed_offender_sar =
            create :offender_sar_case, :closed,
            identifier: 'closed offender sar',
            received_date: @period_end - 1.hours

        @closed_offender_sar1 =
            create :offender_sar_case, :closed,
            identifier: 'closed offender sar1',
            received_date: @period_start

        @closed_sar =
            create :closed_sar,
            identifier: 'closed sar'

        @closed_foi =
            create :closed_case,
            identifier: 'closed foi'


        @report = R401OffenderSarClosedCasesReport.new(
          user: @user,
          period_start: @period_start,
          period_end: @period_end
        )
      end

      context '#case_scope' do
        it 'ignores any selected periods' do
          expected = [@closed_offender_sar.name, @closed_offender_sar1.name]
          expect(@report.case_scope.map(&:name)).to match_array(expected)
        end
      end

      context '#run' do
        it 'creates a job to generate closed cases' do
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
