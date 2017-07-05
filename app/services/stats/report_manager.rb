module Stats
  class ReportManager

    include ActiveSupport::Inflector

    REPORTS = {
      'R001' => R001RespondedCaseTimelinessReport,
      'R002' => R002OpenFoiCasesByTeamReport
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
