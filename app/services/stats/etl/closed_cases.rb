require 'csv'

module Stats
  module ETL
    class ClosedCases < BaseClosedCases
      RESULT_NAME = 'closed-cases'.freeze


      def result_name
        RESULT_NAME
      end

      private

      def columns
        @_columns ||= begin
          CSVExporter::CSV_COLUMN_HEADINGS.map { |f| f.parameterize.underscore }
        end
      end

      def heading
        @_heading ||= begin
          CSV.generate_line(CSVExporter::CSV_COLUMN_HEADINGS, force_quotes: true)
        end
      end
      
    end
  end
end
