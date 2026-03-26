module Stats
  class StandardSARAnalyser
    COMMON_SUPERHEADINGS = {
      non_trigger_performance: "Non-trigger cases",
      non_trigger_max_achievable: "Max achievable (Non-trigger)",
      non_trigger_total: "Non-trigger cases",
      non_trigger_sar_extensions: "Non-trigger Extended",
      non_trigger_stopped: "Non-trigger Paused",
      non_trigger_responded_in_time: "Non-trigger cases",
      non_trigger_responded_late: "Non-trigger cases",
      non_trigger_open_in_time: "Non-trigger cases",
      non_trigger_open_late: "Non-trigger cases",
      trigger_performance: "Trigger cases",
      trigger_max_achievable: "Max achievable (Trigger)",
      trigger_total: "Trigger cases",
      trigger_sar_extensions: "Trigger Extended",
      trigger_stopped: "Trigger Paused",
      trigger_responded_in_time: "Trigger cases",
      trigger_responded_late: "Trigger cases",
      trigger_open_in_time: "Trigger cases",
      trigger_open_late: "Trigger cases",
      overall_performance: "Overall",
      overall_max_achievable: "Max achievable (Overall)",
      overall_total: "Overall",
      overall_sar_extensions: "Overall Extended",
      overall_stopped: "Overall Paused",
      overall_responded_in_time: "Overall",
      overall_responded_late: "Overall",
      overall_open_in_time: "Overall",
      overall_open_late: "Overall",
    }.freeze

    COMMON_COLUMNS = {
      non_trigger_performance: "Performance %",
      non_trigger_max_achievable: "Performance %",
      non_trigger_total: "Total received",
      non_trigger_sar_extensions: "",
      non_trigger_stopped: "Status - excluded from overall",
      non_trigger_responded_in_time: "Responded - in time",
      non_trigger_responded_late: "Responded - late",
      non_trigger_open_in_time: "Open - in time",
      non_trigger_open_late: "Open - late",
      trigger_performance: "Performance %",
      trigger_max_achievable: "Performance %",
      trigger_total: "Total received",
      trigger_sar_extensions: "",
      trigger_stopped: "Status - excluded from overall",
      trigger_responded_in_time: "Responded - in time",
      trigger_responded_late: "Responded - late",
      trigger_open_in_time: "Open - in time",
      trigger_open_late: "Open - late",
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

    attr_reader :result, :bu_result

    def initialize(kase)
      @kase = kase
      @result = nil
      @bu_result = nil
    end

    def run(*)
      analyse_case_for_main_stats
      analyse_case_for_responding_business_unit

      analyse_case_for_sar_extensions if @kase.sar_extensions.any?
      analyse_case_for_stopped if @kase.stopped?
    end

  private

    def analyse_case_for_main_stats
      timeliness = @kase.closed? ? analyse_closed_case : analyse_open_case
      @result = add_trigger_state(timeliness)
    end

    def add_trigger_state(timeliness)
      "#{@kase.trigger_status}_#{timeliness}".to_sym
    end

    # Unassigned cases are considered open in time or open late
    def analyse_case_for_responding_business_unit
      @bu_result =
        if @kase.unassigned?
          analyse_open_case
        elsif @kase.responded?
          analyse_responded_case_for_responding_business_unit
        else
          analyse_open_case_for_responding_business_unit
        end
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

    def analyse_responded_case_for_responding_business_unit
      if @kase.business_unit_responded_in_time?
        RESPONDED_IN_TIME
      else
        RESPONDED_LATE
      end
    end

    def analyse_open_case_for_responding_business_unit
      if @kase.business_unit_already_late?
        OPEN_LATE
      else
        OPEN_IN_TIME
      end
    end

    def analyse_case_for_stopped
      @result = "#{@kase.trigger_status}_stopped".to_sym
    end

    def analyse_case_for_sar_extensions
      @result = "#{@kase.trigger_status}_sar_extensions".to_sym
    end
  end
end
