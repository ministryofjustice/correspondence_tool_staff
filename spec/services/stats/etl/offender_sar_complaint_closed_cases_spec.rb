require "rails_helper"
require "fileutils"
require "csv"

# rubocop:disable RSpec/BeforeAfterAll
module Stats
  module ETL
    describe OffenderSarComplaintClosedCases do
      let(:default_retrieval_scope) do
        Case::SAR::OffenderComplaint.all
      end

      before(:all) do
        7.times do
          ::Warehouse::CaseReport.generate(create(:offender_sar_complaint))
        end

        @etl = described_class.new(retrieval_scope: Case::SAR::OffenderComplaint.all)
      end

      after(:all) do
        DbHousekeeping.clean(seed: true)
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
            case field
            when " case when number_of_days_late > 0 then 'out of time' else 'in time' end "
              expect(case_report).to respond_to "number_of_days_late"
            when "number_of_final_pages::integer - number_of_exempt_pages::integer"
              expect(case_report).to respond_to "number_of_final_pages"
              expect(case_report).to respond_to "number_of_exempt_pages"
            else
              expect(case_report).to respond_to field
            end
          end
        end
      end
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll
