module Stats
  class AppealAnalyser < CaseAnalyser
    IR_APPEAL_COLUMNS = {
      ir_appeal_performance: "Performance %",
      ir_appeal_total: "Total received",
      ir_appeal_responded_in_time: "Responded - in time",
      ir_appeal_responded_late: "Responded - late",
      ir_appeal_open_in_time: "Open - in time",
      ir_appeal_open_late: "Open - late",
    }.freeze

    IR_APPEAL_SUPERHEADINGS = {
      ir_appeal_performance: "Internal reviews",
      ir_appeal_total: "Internal reviews",
      ir_appeal_responded_in_time: "Internal reviews",
      ir_appeal_responded_late: "Internal reviews",
      ir_appeal_open_in_time: "Internal reviews",
      ir_appeal_open_late: "Internal reviews",
    }.freeze

    ICO_APPEAL_COLUMNS = {
      ico_appeal_performance: "Performance %",
      ico_appeal_total: "Total received",
      ico_appeal_responded_in_time: "Responded - in time",
      ico_appeal_responded_late: "Responded - late",
      ico_appeal_open_in_time: "Open - in time",
      ico_appeal_open_late: "Open - late",
    }.freeze

    ICO_APPEAL_SUPERHEADINGS = {
      ico_appeal_performance: "ICO appeals",
      ico_appeal_total: "ICO appeals",
      ico_appeal_responded_in_time: "ICO appeals",
      ico_appeal_responded_late: "ICO appeals",
      ico_appeal_open_in_time: "ICO appeals",
      ico_appeal_open_late: "ICO appeals",
    }.freeze

    SAR_IR_APPEAL_COLUMNS = {
      sar_ir_appeal_performance: "Performance %",
      sar_ir_appeal_total: "Total received",
      sar_ir_appeal_responded_in_time: "Responded - in time",
      sar_ir_appeal_responded_late: "Responded - late",
      sar_ir_appeal_open_in_time: "Open - in time",
      sar_ir_appeal_open_late: "Open - late",
    }.freeze

    SAR_IR_APPEAL_SUPERHEADINGS = {
      sar_ir_appeal_performance: "SAR Internal reviews",
      sar_ir_appeal_total: "SAR Internal reviews",
      sar_ir_appeal_responded_in_time: "SAR Internal reviews",
      sar_ir_appeal_responded_late: "SAR Internal reviews",
      sar_ir_appeal_open_in_time: "SAR Internal reviews",
      sar_ir_appeal_open_late: "SAR Internal reviews",
    }.freeze

    def initialize(kase)
      @kase = kase
      @result = nil
    end

    def result
      analyse_case
      @result
    end

  private

    def analyse_case
      timeliness = @kase.closed_for_reporting_purposes? ? analyse_closed_case : analyse_open_case
      @result = add_type(timeliness)
    end

    def analyse_closed_case
      @kase.responded_in_time? ? :responded_in_time : :responded_late
    end

    def analyse_open_case
      @kase.already_late? ? :open_late : :open_in_time
    end

    def add_type(timeliness)
      if @kase.is_a?(Case::SAR::InternalReview)
        status = "sar_ir_appeal_#{timeliness}"
      else
        appeal_type = @kase.is_a?(Case::ICO::Base) ? "ico" : "ir"
        status = "#{appeal_type}_appeal_#{timeliness}"
      end
      status.to_sym
    end
  end
end
