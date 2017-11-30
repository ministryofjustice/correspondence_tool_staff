module Stats
  class ReportManager

    include ActiveSupport::Inflector

    REPORTS = {
      'R002' => R002AppealsPerformanceReport,
      'R003' => R003BusinessUnitPerformanceReport,
      'R003ap' => R003AppealsPerformanceReport,
      'R005' => R005MonthlyPerformanceReport,
      'R004' => R004CabinetOfficeReport
    }.freeze

    def reports
      REPORTS
    end



    def report_class(report_id)
      REPORTS[report_id]
    end

    def report_object(report_id)
      REPORTS[report_id].new
    end

    def filename(report_id)
      "#{REPORTS[report_id].to_s.underscore.sub('stats/', '')}.csv"
    end

  end
end
