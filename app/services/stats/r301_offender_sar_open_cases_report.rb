require 'csv'

module Stats
  class R301OffenderSarOpenCasesReport < BaseReport

    COLUMN_HEADINGS = [
        'Case number',
        'Date received at MOJ',
        'Final deadlinne', 
        'Who is making the request?',
        'Data subject name',
        'Subject type',
        'Page count',
        'Timeliness (in time/out of time)',
        'Case state',
        'Times Taken',
        'Data types'
    ]

    def self.title
      'Open cases report for Offender SAR'
    end

    def self.description
      'The list of open Offender SAR cases within allowed and filtered scope'
    end

    def initialize(**options)
      super(**options)
      @case_scope = options[:case_scope] || Case::SAR::Offender.all
    end 

    def case_scope
      @case_scope.where(type: 'Case::SAR::Offender').where("current_state != 'closed'")
    end

    def run(*)
    end

    def analyse_case(kase)
      [
        kase.number, 
        kase.received_date, 
        kase.external_deadline,
        kase.third_party? ? kase.third_party_relationship : 'data subject',
        kase.subject_full_name, 
        kase.subject_type, 
        kase.page_count, 
        kase.already_late? ? 'out of time' : 'in time', 
        kase.current_state,
        # kase.time_taken_for_sending_data, 
        # kase.datatypes
      ]
    end

    def to_csv
      CSVGenerator.new(self.case_scope, self)
    end

    def report_type
      ReportType.r301
    end
  end
end
