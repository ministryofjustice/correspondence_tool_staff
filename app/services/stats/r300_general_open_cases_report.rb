require 'csv'

module Stats
  class R300GeneralOpenCasesReport < BaseReport

    COLUMN_HEADINGS = CSVExporter::CSV_COLUMN_HEADINGS

    def self.title
      'Open cases report'
    end

    def self.description
      'The list of open within allowed and filtered scope'
    end

    def initialize(**options)
      super(**options)
      @case_scope = options[:case_scope] || Case::Base.all
    end 

    def case_scope
      @case_scope.where("current_state != 'closed'")
    end

    def run(*)
    end

    def analyse_case(kase)
      kase.to_csv()
    end

    def to_csv
      CSVGenerator.new(self.case_scope, self)
    end

    def report_type
      ReportType.r300
    end
  end
end
