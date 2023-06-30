require "rails_helper"

module ReportingPeriod
  describe LastMonth do
    describe "#initialize" do
      it "works on first day of next month" do
        date = Date.new(1998, 10, 1)
        expected_start = Date.new(1998, 9, 1)
        expected_end = Date.new(1998, 9, 30)

        Timecop.freeze(date) do
          last_month = described_class.new

          expect(last_month.period_start.to_date).to eq expected_start
          expect(last_month.period_end.to_date).to eq expected_end
        end
      end
    end
  end
end
