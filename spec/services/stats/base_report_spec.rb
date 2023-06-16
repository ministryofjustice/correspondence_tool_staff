require "rails_helper"

module Stats
  class DummyReport < BaseReport
    def report_type
      ReportType.first
    end
  end

  describe BaseReport do
    before(:all) { create_report_type(abbr: :r006) }
    after(:all) { DbHousekeeping.clean(seed: true) }

    describe ".new" do
      it "raises if BaseReport is instantiated" do
        expect {
          described_class.new
        }.to raise_error RuntimeError, "Cannot instantiate Stats::BaseReport - use derived class instead"
      end

      it "does not raise if derived class instantiated" do
        expect {
          DummyReport.new
        }.not_to raise_error
      end
    end

    describe "#title" do
      it "raises if derived report does not implement #title" do
        expect {
          DummyReport.title
        }.to raise_error RuntimeError, "Stats::DummyReport doesn't implement .title method"
      end
    end

    describe "#description" do
      it "raises if derived report does not implement #title" do
        expect {
          DummyReport.description
        }.to raise_error RuntimeError, "Stats::DummyReport doesn't implement .description method"
      end
    end
  end
end
