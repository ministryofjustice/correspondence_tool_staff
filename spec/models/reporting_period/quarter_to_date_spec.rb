require "rails_helper"

module ReportingPeriod
  describe QuarterToDate do
    let!(:apr_1)   { Date.new(2003, 4, 1) }
    let!(:jun_30)  { Date.new(2003, 6, 30) }

    describe "#initialize" do
      it "works on first day of quarter" do
        Timecop.freeze(apr_1) do
          quarter_to_date = described_class.new

          expect(quarter_to_date.period_start.to_date).to eq apr_1
          expect(quarter_to_date.period_end.to_date).to eq apr_1
        end
      end

      it "works on last day of quarter" do
        date = jun_30 + 23.hours

        Timecop.freeze(date) do
          quarter_to_date = described_class.new

          expect(quarter_to_date.period_start.to_date).to eq apr_1
          expect(quarter_to_date.period_end.to_date).to eq jun_30
        end
      end
    end
  end
end
