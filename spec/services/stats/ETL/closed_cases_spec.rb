require 'rails_helper'

module Stats
  module ETL
    describe ClosedCases do
      describe '#initialize' do
        it 'returns self' do
          report = Stats::ETL::ClosedCases.new
          expect(report).to be_a Stats::ETL::ClosedCases
        end
      end

      describe '#extract' do
        it 'returns self' do

        end
      end

      describe '#transform' do
        it 'returns self' do

        end
      end

      describe '#load' do
        it 'returns self' do

        end
      end
    end
  end
end
