module DeadlineCalculator
  class CalendarDays

    attr_reader :kase

    def initialize(kase)
      @kase = kase
    end

    def escalation_deadline
      kase.created_at.to_date + kase.correspondence_type.escalation_time_limit.days
    end

    def internal_deadline     # aka draft deadline
      kase.received_date + kase.correspondence_type.internal_time_limit.days
    end

    def external_deadline
      kase.received_date + kase.correspondence_type.external_time_limit.days
    end

    def business_unit_deadline_for_date(date)
      deadline_method  = @kase.flagged? ? :internal_time_limit : :external_time_limit
      num_days = @kase.correspondence_type.__send__(deadline_method)
      date + num_days.days
    end


  end
end
