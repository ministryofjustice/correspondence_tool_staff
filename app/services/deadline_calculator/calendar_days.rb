module DeadlineCalculator
  class CalendarDays

    attr_reader :kase

    def initialize(kase)
      @kase = kase
    end

    def escalation_deadline
      calculate_days_from kase.correspondence_type.escalation_time_limit.days,
                          kase.created_at.to_date
    end

    def internal_deadline     # aka draft deadline
      calculate_days_from kase.correspondence_type.internal_time_limit.days,
                          kase.received_date
    end

    def external_deadline
      calculate_days_from kase.correspondence_type.external_time_limit.days,
                          kase.received_date
    end

    private

    def calculate_days_from(days, start_date)
      days.since start_date
    end
  end
end
