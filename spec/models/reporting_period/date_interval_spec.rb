require "rails_helper"

module ReportingPeriod
  describe DateInterval do
    let(:feb_1)   { Date.new(2018, 2, 1) }
    let(:apr_30)  { Date.new(2018, 4, 30) }

    describe "#initialize" do
      it "sets date periods" do
        date_interval = described_class.new(
          period_start: feb_1,
          period_end: apr_30,
        )

        expect(date_interval.period_start.to_date).to eq feb_1
        expect(date_interval.period_end.to_date).to eq apr_30
      end
    end
  end
end
