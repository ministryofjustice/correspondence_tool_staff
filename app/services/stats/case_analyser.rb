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
      non_trigger_performance:         'Non-trigger FOIs',
      non_trigger_total:               'Non-trigger FOIs',
      non_trigger_responded_in_time:   'Non-trigger FOIs',
      non_trigger_responded_late:      'Non-trigger FOIs',
      non_trigger_open_in_time:        'Non-trigger FOIs',
      non_trigger_open_late:           'Non-trigger FOIs',
      trigger_performance:             'Trigger FOIs',
      trigger_total:                   'Trigger FOIs',
      trigger_responded_in_time:       'Trigger FOIs',
      trigger_responded_late:          'Trigger FOIs',
      trigger_open_in_time:            'Trigger FOIs',
      trigger_open_late:               'Trigger FOIs',
      overall_performance:             'Overall',
      overall_total:                   'Overall',
      overall_responded_in_time:       'Overall',
      overall_responded_late:          'Overall',
      overall_open_in_time:            'Overall',
      overall_open_late:               'Overall',

    }.freeze

    APPEAL_COLUMNS = {
      appeal_performance:         'Performance %',
      appeal_total:               'Total received',
      appeal_responded_in_time:   'Responded - in time',
      appeal_responded_late:      'Responded - late',
      appeal_open_in_time:        'Open - in time',
      appeal_open_late:           'Open - late',

    }.freeze

    APPEAL_SUPERHEADINGS = {
      appeal_performance:         'Internal reviews',
      appeal_total:               'Internal reviews',
      appeal_responded_in_time:   'Internal reviews',
      appeal_responded_late:      'Internal reviews',
      appeal_open_in_time:        'Internal reviews',
      appeal_open_late:           'Internal reviews',

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
  end
end
