require "csv"

module Stats
  module ETL
    class OffenderSarClosedCases < BaseClosedCases
      RESULT_NAME = "offender-sar-closed-cases".freeze

      CSV_COLUMN_HEADINGS = [
        "Case number",
        "Data subject name",
        "Subject type",
        "Who is making the request?",
        "Company name",
        "Date received at MOJ",
        "Date case closed",
        "Timeliness (in time/out of time)",
        "No of days taken",
        "Pages for dispatch",
        "Exempt pages",
        "Final page count",
      ].freeze

      FIELD_COLUMNS = [
        "number",
        "sar_subject_full_name",
        "sar_subject_type",
        "requester_type",
        "third_party_company_name",
        "date_received",
        "date_responded",
        " case when number_of_days_late > 0 then 'out of time' else 'in time' end ",
        "number_of_days_taken",
        "number_of_final_pages::integer - number_of_exempt_pages::integer",
        "number_of_exempt_pages",
        "number_of_final_pages",
      ].freeze

      def result_name
        RESULT_NAME
      end

    private

      def columns
        @_columns ||= OffenderSarClosedCases::FIELD_COLUMNS
      end

      def heading
        @_heading ||= CSV.generate_line(OffenderSarClosedCases::CSV_COLUMN_HEADINGS, force_quotes: true)
      end
    end
  end
end
