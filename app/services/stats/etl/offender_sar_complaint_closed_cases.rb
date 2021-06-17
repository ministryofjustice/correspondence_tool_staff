require 'csv'

module Stats
  module ETL
    class OffenderSarComplaintClosedCases < BaseClosedCases

      RESULT_NAME = 'offender-sar-complaint-closed-cases'.freeze

      CSV_COLUMN_HEADINGS = [
        'Case number',
        'Case type', 
        'Nature of complaint', 
        'Data subject name',
        'Subject type',
        'Who is making the request?',
        'Company name',
        'Date received at MOJ',
        'Who was dealing with this case',
        'Date case closed',
        'Timeliness (in time/out of time)',
        'No of days taken',
        'Pages for dispatch',
        'Exempt pages',
        'Final page count',
        'Outcome of ICO complaint', 
        'Outcome of litigation complaint', 
        'Cost paid', 
        'Settlement paid'
      ]

      FIELD_COLUMNS = [
        'number',
        'case_type', 
        'complaint_subtype',
        'sar_subject_full_name',
        'sar_subject_type',
        'requester_type',
        'third_party_company_name',
        'date_received',
        'responder', 
        'date_responded',
        " case when number_of_days_late > 0 then 'out of time' else 'in time' end ",
        'number_of_days_taken',
        'number_of_final_pages::integer - number_of_exempt_pages::integer',
        'number_of_exempt_pages',
        'number_of_final_pages', 
        'appeal_outcome', 
        'outcome', 
        'total_cost', 
        'settlement_cost'
      ]

      def result_name
        RESULT_NAME
      end

      private

      def columns
        @_columns ||= begin
          OffenderSarComplaintClosedCases::FIELD_COLUMNS
        end
      end

      def heading
        @_heading ||= begin
          CSV.generate_line(OffenderSarComplaintClosedCases::CSV_COLUMN_HEADINGS, force_quotes: true)
        end
      end

    end
  end
end
