require "rails_helper"
require "fileutils"
require "csv"

# rubocop:disable RSpec/BeforeAfterAll
module Stats
  module ETL
    describe ClosedCases do
      let(:default_retrieval_scope) do
        Case::Base.all
      end

      before(:all) do
        7.times do
          ::Warehouse::CaseReport.generate(create(:foi_case))
        end

        @etl = described_class.new(retrieval_scope: Case::Base.all)
      end

      after(:all) do
        DbHousekeeping.clean(seed: true)
      end

      describe "#initialize" do
        it "generates a single zip file from multiple csv files" do
          fragments_dir = @etl.send(:folder)

          expect(Dir["#{fragments_dir}/closed-cases.csv"].first).to be_present
          expect(Dir["#{fragments_dir}/closed-cases.zip"].first).to be_present
        end
      end

      describe "#heading" do
        it "returns a single line CSV" do
          header = @etl.send(:heading)
          expect(header.size).to be > 0
          expect(header).to match(/([a-zA-Z0-9,\s])+/)
          expect(header.ends_with?("\n")).to be true
          expect(header.last).not_to be ","
        end
      end

      describe "#columns" do
        it "returns list of Warehouse::CaseReport field names" do
          case_report = ::Warehouse::CaseReport.new
          @etl.send(:columns).each do |field|
            expect(case_report).to respond_to field
          end
        end
      end
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll
