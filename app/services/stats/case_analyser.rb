module Stats

  class CaseAnalyser

    COMMON_COLUMNS = {
      non_trigger_performance:         'Performance %',
      non_trigger_total:               'Total received',
      non_trigger_responded_in_time:   'Responded - in time',
      non_trigger_responded_late:      'Responded - late',
      non_trigger_open_in_time:        'Open - in time',
      non_trigger_open_late:           'Open - late',
      trigger_performance:             'Performance %',
      trigger_total:                   'Total received',
      trigger_responded_in_time:       'Responded - in time',
      trigger_responded_late:          'Responded - late',
      trigger_open_in_time:            'Open - in time',
      trigger_open_late:               'Open - late',
      overall_performance:             'Performance %',
      overall_total:                   'Total received',
      overall_responded_in_time:       'Responded - in time',
      overall_responded_late:          'Responded - late',
      overall_open_in_time:            'Open - in time',
      overall_open_late:               'Open - late',
    }.freeze

    COMMON_SUPERHEADINGS = {
      non_trigger_performance:         'Non-trigger cases',
      non_trigger_total:               'Non-trigger cases',
      non_trigger_responded_in_time:   'Non-trigger cases',
      non_trigger_responded_late:      'Non-trigger cases',
      non_trigger_open_in_time:        'Non-trigger cases',
      non_trigger_open_late:           'Non-trigger cases',
      trigger_performance:             'Trigger cases',
      trigger_total:                   'Trigger cases',
      trigger_responded_in_time:       'Trigger cases',
      trigger_responded_late:          'Trigger cases',
      trigger_open_in_time:            'Trigger cases',
      trigger_open_late:               'Trigger cases',
      overall_performance:             'Overall',
      overall_total:                   'Overall',
      overall_responded_in_time:       'Overall',
      overall_responded_late:          'Overall',
      overall_open_in_time:            'Overall',
      overall_open_late:               'Overall',

    }.freeze

    attr_reader :result, :bu_result

    def initialize(kase)
      @kase = kase
      @result = nil
      @bu_result = nil
    end

    def run
      analyse_case_for_main_stats
      analyse_case_for_responding_business_unit
    end

    private

    def analyse_case_for_main_stats
      timeliness = @kase.closed? ? analyse_closed_case : analyse_open_case
      @result = add_trigger_state(timeliness)
    end

    def analyse_closed_case
      @kase.responded_in_time? ? :responded_in_time : :responded_late
    end

    def analyse_open_case
      @kase.already_late? ? :open_late : :open_in_time
    end

    def add_trigger_state(timeliness)
      status = @kase.flagged? ? 'trigger_' + timeliness.to_s : 'non_trigger_' + timeliness.to_s
      status.to_sym
    end

    def analyse_case_for_responding_business_unit
      @bu_result = @kase.responded? ? analyse_responded_case_for_responding_business_unit : analyse_open_case_for_responding_business_unit
    end

    def analyse_responded_case_for_responding_business_unit
      @kase.business_unit_responded_in_time? ? :responded_in_time : :responded_late
    end

    def analyse_open_case_for_responding_business_unit
      @kase.business_unit_already_late? ? :open_late : :open_in_time
    end
  end
end
