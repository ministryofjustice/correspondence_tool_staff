module Stats

  class AppealAnalyser < CaseAnalyser
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
      @result = add_type(timeliness)
    end

    def analyse_closed_case
      @kase.responded_in_time? ? :responded_in_time : :responded_late
    end

    def analyse_open_case
      @kase.already_late? ? :open_late : :open_in_time
    end

    def add_type(timeliness)
      status = 'appeal_' + timeliness.to_s
      status.to_sym
    end
  end
end
