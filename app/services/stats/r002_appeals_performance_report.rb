module Stats
  class R002AppealsPerformanceReport < BaseAppealsPerformanceReport

    def superheadings
      [
        ["#{self.class.title} - #{reporting_period}"],
        R002_SPECIFIC_SUPERHEADINGS
            .merge(AppealAnalyser::IR_APPEAL_SUPERHEADINGS)
            .merge(AppealAnalyser::ICO_APPEAL_SUPERHEADINGS).values
      ]
    end

    def self.title
      'Appeals report (FOI)'
    end

    def self.description
      'Shows all internal reviews and ICO appeals for FOIs which are open, or have been closed this month, analysed by timeliness'
    end

    def report_type
      ReportType.r002
    end

    def case_ids
      ir_case_ids = CaseSelector.new(Case::FOI::InternalReview.all).ids_for_period_appeals(@period_start, @period_end)
      ico_case_ids = CaseSelector.new(Case::ICO::Base.all).ids_for_period_appeals(@period_start, @period_end)
      ir_case_ids + ico_case_ids
    end

    private

    def appeal_types
      %w{ ir ico }
    end

    def column_headings
      R002_SPECIFIC_COLUMNS
          .merge(AppealAnalyser::IR_APPEAL_COLUMNS)
          .merge(AppealAnalyser::ICO_APPEAL_COLUMNS)
    end
  end
end
