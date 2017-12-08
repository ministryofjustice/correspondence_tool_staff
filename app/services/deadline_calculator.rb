class DeadlineCalculator

  class << self

    def escalation_deadline(kase, start_from=kase.created_at.to_date)
      days_after_day_one = kase.category.escalation_time_limit - 1
      days_after_day_one.business_days.after(start_date(start_from))
    end

    def internal_deadline(kase)      # aka draft deadline
      internal_deadline_for_date(kase.category, start_date(kase.received_date))
    end

    def internal_deadline_for_date(category, date)
      days_after_day_one = category.internal_time_limit - 1
      days_after_day_one.business_days.after(date)
    end

    def external_deadline(kase)
      days_after_day_one = kase.category.external_time_limit - 1
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
