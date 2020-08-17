require 'csv'

module Stats
  module ETL
    class OffenderSarClosedCases < BaseClosedCases

      RESULT_NAME = 'offender-sar-closed-cases'.freeze

      CSV_COLUMN_HEADINGS = [
        'Case number',
        'Data subject name',
        'Subject type',
        'Who is making the request?',
        'Date received at MOJ',
        'Date case closed', 
        'Timeliness (in time/out of time)',
      ]

      FIELD_COLUMNS = [
        'number', 
        'sar_subject_type', 
        'sar_subject_type',
        'requester_type', 
        'date_received',
        'date_responded', 
        " case when number_of_days_late > 0 then 'in time' else 'out of time' end ", 
      ]

      def result_name
        RESULT_NAME
      end

      private

      def columns
        @_columns ||= begin
          OffenderSarClosedCases::FIELD_COLUMNS
        end
      end

      def heading
        @_heading ||= begin
          CSV.generate_line(OffenderSarClosedCases::CSV_COLUMN_HEADINGS, force_quotes: true)
        end
      end

    end
  end
end
