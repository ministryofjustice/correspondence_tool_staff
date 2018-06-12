module Stats
  class CaseSelector

    # can be instantiated wither with a Class name, or a scope
    # e.g.
    #
    #    Stats::CaseSelector.new(Case::FOI::Standard)
    #    Stats::CaseSelector.new(Case::Base.closed)
    #
    def initialize(scope_or_class = Case::Base)
      @scope = scope_or_class.is_a?(Class) ? scope_or_class.all : scope_or_class
    end


    def ids_for_period(period_start, period_end)
      (ids_for_cases_received_in_period(period_start, period_end) +
        ids_for_cases_open_at_start_of_period_and_since_closed(period_start, period_end) +
        ids_for_cases_open_during_period_still_not_closed(period_start, period_end)).flatten.uniq
    end

    def ids_for_cases_received_in_period(period_start, period_end)
      @scope.where(received_date: [period_start..period_end]).pluck(:id)
    end

    def ids_for_period_appeals(period_start, period_end)
      closed_case_ids =  @scope.appeal.closed.where(date_responded: [period_start..period_end]).pluck(:id)
      open_case_ids = @scope.appeal.opened.pluck(:id)
      (closed_case_ids + open_case_ids).uniq
    end

    def ids_for_appeals_received_in_period(period_start, period_end)
      @scope.appeal.where(received_date: [period_start..period_end]).pluck(:id)
    end

    def ids_for_cases_open_at_start_of_period_and_since_closed(period_start, _period_end)
      @scope.where('received_date < ? and date_responded >= ?', period_start, period_start).pluck(:id)
    end

    def ids_for_cases_open_during_period_still_not_closed(_period_start, period_end)
      @scope.where('received_date <= ? and date_responded is null', period_end).pluck(:id)
    end

  end
end
