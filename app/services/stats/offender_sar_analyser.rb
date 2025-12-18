module Stats
  class OffenderSARAnalyser
    COMMON_SUPERHEADINGS = {
      overall_performance: "Overall",
      overall_max_achievable: "Max achieveable",
      overall_total: "Overall",
      overall_sar_extensions: "Extended",
      overall_stopped: "Paused",
      overall_responded_in_time: "Overall",
      overall_responded_late: "Overall",
      overall_open_in_time: "Overall",
      overall_open_late: "Overall",
    }.freeze

    COMMON_COLUMNS = {
      overall_performance: "Performance %",
      overall_max_achievable: "Performance %",
      overall_total: "Total received",
      overall_sar_extensions: "",
      overall_stopped: "Status - excluded from overall",
      overall_responded_in_time: "Responded - in time",
      overall_responded_late: "Responded - late",
      overall_open_in_time: "Open - in time",
      overall_open_late: "Open - late",
    }.freeze

    RESPONDED_IN_TIME = :responded_in_time
    RESPONDED_LATE    = :responded_late
    OPEN_LATE         = :open_late
    OPEN_IN_TIME      = :open_in_time

    attr_reader :result

    def initialize(kase)
      @kase = kase
      @result = nil
    end

    def run(*)
      analyse_case_for_main_stats
    end

  private

    def analyse_case_for_main_stats
      timeliness = @kase.closed? ? analyse_closed_case : analyse_open_case
      @result = add_trigger_state(timeliness)
    end

    def add_trigger_state(timeliness)
      "overall_#{timeliness}".to_sym
    end

    def analyse_closed_case
      if @kase.responded_in_time?
        RESPONDED_IN_TIME
      else
        RESPONDED_LATE
      end
    end

    def analyse_open_case
      if @kase.already_late?
        OPEN_LATE
      else
        OPEN_IN_TIME
      end
    end
  end
end
