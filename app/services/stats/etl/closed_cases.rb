require "csv"

module Stats
  module ETL
    class ClosedCases < BaseClosedCases
      RESULT_NAME = "closed-cases".freeze

      def result_name
        RESULT_NAME
      end

    private

      def columns
        @columns ||= CSVExporter::CSV_COLUMN_FIELDS
      end

      def heading
        @heading ||= CSV.generate_line(CSVExporter::CSV_COLUMN_HEADINGS, force_quotes: true)
      end
    end
  end
end
