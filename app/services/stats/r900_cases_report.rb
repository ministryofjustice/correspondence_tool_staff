require "csv"

module Stats
  class R900CasesReport < BaseReport
    CSV_COLUMN_HEADINGS = CSVExporter::CSV_COLUMN_HEADINGS

    def self.title
      "Cases report"
    end

    def self.description
      "The list of cases within allowed and filtered scope"
    end

    def initialize(**options)
      super(**options)
      @case_scope = options[:case_scope] || Case::Base.all
    end

    attr_reader :case_scope

    def run(*); end

    def analyse_case(kase)
      kase.to_csv
    end

    def to_csv
      CSVGenerator.new(case_scope, self)
    end

    def report_type
      ReportType.r900
    end
  end
end
