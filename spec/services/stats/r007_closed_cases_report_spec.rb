require 'rails_helper'

module Stats
  describe R007ClosedCasesReport do
    before(:all) { create_report_type(abbr: :r007)}
    after(:all) { DbHousekeeping.clean(seed: true) }

    describe '.title' do
      it 'returns correct title' do
        expect(R007ClosedCasesReport.title).to eq 'Closed cases report'
      end
    end

    describe '.description' do
      it 'returns correct description' do
        expect(R007ClosedCasesReport.description)
          .to eq 'Entire list of closed cases'
      end
    end

    describe 'reporting' do
      before(:all) do
        @period_start = Date.new(2018, 12, 20)
        @period_end = Date.new(2018, 12, 31)
        @user = create :manager

        @cases = {
          closed_sar: {
            type: :closed_sar,
            received: @period_end - 1.hours,
          },
          closed_foi: {
            type: :closed_case,
            received: @period_start,
          },
          outside_period_foi: {
            type: :closed_case,
            received: @period_end + 1.days
          },
          responded_foi: {
            type: :responded_case,
            received: @period_start + 1.hour,
          },
          open_foi: {
            type: :accepted_case,
            received: @period_start + 1.days,
            state: 'totally-not-accepted-really'
          },
        }

        @cases.each do |key, options|
          kase = build(
            options[:type],
            name: key,
            received_date: options[:received],
            current_state: options[:state] || 'closed'
          )

          kase.save(validate: false)
          @cases[key][:case] = kase
        end

        @report = R007ClosedCasesReport.new(
          user: @user,
          period_start: @period_start,
          period_end: @period_end
        )
      end

      context '#case_scope' do
        it 'ignores any selected periods' do
          expected = %w[closed_sar closed_foi outside_period_foi responded_foi]
          expect(@report.case_scope.map(&:name)).to match_array(expected)
        end
      end

      context '#run' do
        it 'returns only cases within the selected period' do
          expected = %w[closed_sar closed_foi responded_foi]
          expect(@report.run.map(&:name)).to match_array(expected)
        end
      end
    end
  end
end
