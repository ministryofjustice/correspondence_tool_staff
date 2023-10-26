module DeadlineCalculator
  class CalendarDays
    attr_reader :kase

    def initialize(kase)
      @kase = kase
    end

    def days_taken(start_date, end_date)
      (end_date - start_date).to_i + 1
    end

    def days_late(start_date, end_date)
      (end_date - start_date).to_i
    end

    def days_before(number, date)
      date - number.days
    end

    def escalation_deadline
      kase.created_at.to_date + kase.correspondence_type.escalation_time_limit.days
    end

    # aka draft deadline
    def internal_deadline
      kase.received_date + kase.correspondence_type.internal_time_limit.days
    end

    def internal_deadline_for_date(correspondence_type, date)
      days = correspondence_type.internal_time_limit.days
      date + days
    end

    def external_deadline
      kase.received_date + kase.correspondence_type.external_time_limit.days
    end

    def extension_deadline(time_limit)
      kase.received_date + (time_limit + kase.correspondence_type.external_time_limit).days
    end

    def max_allowed_deadline_date(time_limit = nil)
      time_limit ||= (kase.correspondence_type.extension_time_limit || 0)
      kase.received_date + (time_limit + kase.correspondence_type.external_time_limit).days
    end

    def business_unit_deadline_for_date(date)
      deadline_method = @kase.flagged? ? :internal_time_limit : :external_time_limit
      num_days = @kase.correspondence_type.__send__(deadline_method)
      date + num_days.days
    end

    def time_units_desc_for_deadline(time_limit = 1)
      "calendar #{'day'.pluralize(time_limit)}".freeze
    end
  end
end
