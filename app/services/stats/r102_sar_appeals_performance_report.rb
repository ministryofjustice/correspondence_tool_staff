module Stats
  class R102SarAppealsPerformanceReport < BaseAppealsPerformanceReport

    def superheadings
      [
        ["#{self.class.title} - #{reporting_period}"],
        R002_SPECIFIC_SUPERHEADINGS
            .merge(AppealAnalyser::ICO_APPEAL_SUPERHEADINGS)
            .merge(AppealAnalyser::SAR_IR_APPEAL_SUPERHEADINGS).values
      ]
    end

    def self.title
      'SAR Appeal performance stats'
    end

    def self.description
      'Shows all ICO appeals, and SAR IRs which are open, or have been closed this month, analysed by timeliness'
    end

    def case_ids
      ico_sar_case_ids = CaseSelector.new(Case::ICO::SAR.all).ids_for_period_appeals(@period_start, @period_end)
      sar_ir_case_ids = CaseSelector.new(Case::SAR::InternalReview.all).ids_for_period(@period_start, @period_end)
      ico_sar_case_ids + sar_ir_case_ids
    end

    def report_type
      ReportType.r102
    end

    private

    def column_headings
      R002_SPECIFIC_COLUMNS
          .merge(AppealAnalyser::ICO_APPEAL_COLUMNS)
          .merge(AppealAnalyser::SAR_IR_APPEAL_COLUMNS)
    end

    def appeal_types
      %w{ ico sar_ir }
    end
  end
end
