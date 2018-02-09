class DeadlineCalculator

  class << self

    def escalation_deadline(kase, start_from=kase.created_at.to_date)
      days_after_day_one = kase.correspondence_type.escalation_time_limit - 1
      days_after_day_one.business_days.after(start_date(start_from))
    end

    def internal_deadline(kase)      # aka draft deadline
      internal_deadline_for_date(kase.correspondence_type,
                                 start_date(kase.received_date))
    end

    def internal_deadline_for_date(correspondence_type, date)
      days_after_day_one = correspondence_type.internal_time_limit - 1
      days_after_day_one.business_days.after(date)
    end

    def external_deadline(kase)
      days_after_day_one = kase.correspondence_type.external_time_limit - 1
      days_after_day_one.business_days.after(start_date(kase.received_date))
    end

    def start_date(received_date)
      date = received_date + 1
      date += 1 until date.workday?
      date
    end
  end

  private_class_method :start_date
end
