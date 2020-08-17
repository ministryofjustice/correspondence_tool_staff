require 'rails_helper'
require 'fileutils'
require 'csv'

module Stats
  module ETL
    describe OffenderSarClosedCases do
      let(:default_retrieval_scope) {
        Case::SAR::Offender.all
      }

      before(:all) do
        7.times do
          ::Warehouse::CaseReport.generate(create :offender_sar_case)
        end

        @etl = described_class.new(retrieval_scope: Case::SAR::Offender.all)
      end

      describe '#heading' do
        it 'returns a single line CSV' do
          header = @etl.send(:heading)
          expect(header.size).to be > 0
          expect(header).to match(/([a-zA-Z0-9,\s])+/)
          expect(header.ends_with? "\n").to be true
          expect(header.last).not_to be ','
        end
      end

      describe '#columns' do
        it 'returns list of Warehouse::CaseReport field names' do
          case_report = ::Warehouse::CaseReport.new
          @etl.send(:columns).each do |field|
            if field == " case when number_of_days_late > 0 then 'in time' else 'out of time' end "
              expect(case_report).to respond_to 'number_of_days_late'
            else
              expect(case_report).to respond_to field
            end 
          end
        end
      end

    end
  end
end
