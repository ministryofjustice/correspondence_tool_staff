module Stats
  class R102SarAppealsPerformanceReport < BaseAppealsPerformanceReport

    def superheadings
      [
        ["#{self.class.title} - #{reporting_period}"],
        R002_SPECIFIC_SUPERHEADINGS
            .merge(AppealAnalyser::ICO_APPEAL_SUPERHEADINGS).values
      ]
    end

    def self.title
      'SAR Appeal performance stats'
    end

    def self.description
      'Shows all ICO appeals which are open, or have been closed this month, analysed by timeliness'
    end

    def case_ids
      CaseSelector.new(Case::ICO::SAR.all).ids_for_period_appeals(@period_start, @period_end)
    end

    def report_type
      ReportType.r102
    end

    private

    def column_headings
      R002_SPECIFIC_COLUMNS
          .merge(AppealAnalyser::ICO_APPEAL_COLUMNS)
    end

    def appeal_types
      %w{ ico }
    end
  end
end
