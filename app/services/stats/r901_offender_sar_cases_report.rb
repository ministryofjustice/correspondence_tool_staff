require 'csv'

module Stats
  class R901OffenderSarCasesReport < BaseReport

    CSV_COLUMN_HEADINGS = [
        'Case number',
        'Date received at MOJ',
        'Final deadlinne', 
        'Who is making the request?',
        'Data subject name',
        'Subject type',
        'Page count',
        'Timeliness (in time/out of time)',
        'Case state',
        'Days open',
        'Company name', 
        'Data requests completed?'
    ]

    def self.title
      'Cases report for Offender SAR'
    end

    def self.description
      'The list of Offender SAR cases within allowed and filtered scope'
    end

    def initialize(**options)
      super(**options)
      @case_scope = options[:case_scope] || Case::SAR::Offender.all
    end 

    def case_scope
      @case_scope.where(type: 'Case::SAR::Offender')
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
        kase.num_days_taken,
        kase.third_party_company_name,
        kase.data_requests_completed? ? 'Yes' : 'No'
      ]
    end

    def to_csv
      CSVGenerator.new(self.case_scope, self)
    end

    def report_type
      ReportType.r901
    end
  end
end
