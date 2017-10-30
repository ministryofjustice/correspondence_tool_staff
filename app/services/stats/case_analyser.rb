module Stats

  class CaseAnalyser

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
      if @kase.unassigned?
        @result = :unassigned
      else
        analyse_assigned_case
      end
    end

    def analyse_assigned_case
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
