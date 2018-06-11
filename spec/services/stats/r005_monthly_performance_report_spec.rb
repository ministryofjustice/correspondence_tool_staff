require 'rails_helper'

module Stats
  describe R005MonthlyPerformanceReport do

    describe '.title' do
      it 'returns the title' do
        expect(R005MonthlyPerformanceReport.title).to eq 'Monthly report'
      end
    end

    describe '#run and #to_csv' do
      before(:each) do
        Timecop.freeze(2017, 5, 2, 13, 14, 15) do
          2.times { create_case(:trigger_responded_in_time, 3) }
          1.times { create_case(:trigger_responded_late, 3) }
          3.times { create_case(:trigger_responded_in_time, 4) }
          2.times { create_case(:non_trigger_open_in_time, 4) }
          1.times { create_case(:non_trigger_open_late, 4) }

          @expected_results = {
            'March' => {
              month_name:                     'March',
              non_trigger_performance_pctg:   '0.0',
              non_trigger_total:              '0',
              non_trigger_responded_in_time:  '0',
              non_trigger_responded_late:     '0',
              non_trigger_open_in_time:       '0',
              non_trigger_open_late:          '0',
              trigger_perfomance_pctg:        '66.7',
              trigger_total:                  '3',
              trigger_responded_in_time:      '2',
              trigger_responded_late:         '1',
              trigger_open_in_time:           '0',
              trigger_open_late:              '0',
              overall_performance_pctg:       '66.7',
              overall_total:                  '3',
              overall_responded_in_time:      '2',
              overall_responded_late:         '1',
              overall_open_in_time:           '0',
              overall_open_late:              '0',
            },
            'April' => {
              month_name:                     'April',
              non_trigger_performance_pctg:   '0.0',
              non_trigger_total:              '3',
              non_trigger_responded_in_time:  '0',
              non_trigger_responded_late:     '0',
              non_trigger_open_in_time:       '2',
              non_trigger_open_late:          '1',
              trigger_perfomance_pctg:        '100.0',
              trigger_total:                  '3',
              trigger_responded_in_time:      '3',
              trigger_responded_late:         '0',
              trigger_open_in_time:           '0',
              trigger_open_late:              '0',
              overall_performance_pctg:       '75.0',
              overall_total:                  '6',
              overall_responded_in_time:      '3',
              overall_responded_late:         '0',
              overall_open_in_time:           '2',
              overall_open_late:              '1',
            },
            'Total' => {
              month_name:                     'Total',
              non_trigger_performance_pctg:   '0.0',
              non_trigger_total:              '3',
              non_trigger_responded_in_time:  '0',
              non_trigger_responded_late:     '0',
              non_trigger_open_in_time:       '2',
              non_trigger_open_late:          '1',
              trigger_perfomance_pctg:        '83.3',
              trigger_total:                  '6',
              trigger_responded_in_time:      '5',
              trigger_responded_late:         '1',
              trigger_open_in_time:           '0',
              trigger_open_late:              '0',
              overall_performance_pctg:       '71.4',
              overall_total:                  '9',
              overall_responded_in_time:      '5',
              overall_responded_late:         '1',
              overall_open_in_time:           '2',
              overall_open_late:              '1',
            }
          }

          report = R005MonthlyPerformanceReport.new
          report.run
          csv_string = report.to_csv
          @results = CSV.parse(csv_string)
        end
      end

      it 'contains report name and reporting period in row 1 column 1' do
        row_1 = @results.first
        expect(row_1.first).to eq 'Monthly report - 1 Jan 2017 to 2 May 2017'
      end

      it 'contains expected superheadings in row 2' do
        row_2 = @results[1]
        expect(row_2[0]).to eq ''
        (1..6).each { |i| expect(row_2[i]).to eq 'Non-trigger FOIs' }
        (7..12).each { |i| expect(row_2[i]).to eq 'Trigger FOIs'}
        (13..18).each { |i| expect(row_2[i]).to eq 'Overall'}
      end

      it 'contains expected headings in row 3' do
        row_3 = @results[2]
        expect(row_3[0]).to eq 'Month'
        [1, 7, 13].each { |i| expect(row_3[i]).to eq 'Performance %' }
        [2, 8, 14].each { |i| expect(row_3[i]).to eq 'Total received' }
        [3, 9, 15].each { |i| expect(row_3[i]).to eq 'Responded - in time' }
        [4, 10, 16].each { |i| expect(row_3[i]).to eq 'Responded - late' }
        [5, 11, 17].each { |i| expect(row_3[i]).to eq 'Open - in time' }
        [6, 12, 18].each { |i| expect(row_3[i]).to eq 'Open - late' }
      end

      it 'contains month names year to date in first column' do
        expect(@results[3][0]).to eq 'January'
        expect(@results[4][0]).to eq 'February'
        expect(@results[5][0]).to eq 'March'
        expect(@results[6][0]).to eq 'April'
        expect(@results[7][0]).to eq 'May'
        expect(@results[8][0]).to eq 'Total'
      end

      context 'monthly figures' do
        let(:month_rows) do
          {
            'March'   => 5,
            'April'   => 6,
            'Total'   => 8
          }
        end

        it 'contains the correct monthly figures for March, April and Total' do
          month_rows.each do |month_name, actual_results_row_index|
            expected_results = @expected_results[month_name]
            actual_results = @results[actual_results_row_index]
            expect(actual_results).to eq expected_results.values
          end
        end
      end

      context 'defining the period' do
        context 'no period parameters passsed in' do
          it 'defaults from beginning of year to now' do
            Timecop.freeze(Time.local(2017, 12, 7, 12,33,44)) do
              report = R005MonthlyPerformanceReport.new
              expect(report.__send__(:reporting_period)).to eq '1 Jan 2017 to 7 Dec 2017'
            end
          end
        end

        context 'period params are passed in' do
          it 'uses the specify period' do
            d1 = Date.new(2017, 6, 1)
            d2 = Date.new(2017, 6, 30)
            report = R005MonthlyPerformanceReport.new(d1, d2)
            expect(report.__send__(:reporting_period)).to eq '1 Jun 2017 to 30 Jun 2017'
          end
        end
      end
    end

    private

    def create_case(state, month)
      k = create :assigned_case, received_date: Date.new(2017, month, 22)
      analyser = double CaseAnalyser
      allow(CaseAnalyser).to receive(:new).with(k).and_return(analyser)
      expect(analyser).to receive(:run)
      expect(analyser).to receive(:result).and_return(state)
    end

  end
end
