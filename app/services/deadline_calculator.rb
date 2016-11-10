class DeadlineCalculator

  class << self
    def internal_deadline(correspondence)
      days_after_day_one = correspondence.category.internal_time_limit - 1
      days_after_day_one.business_days.after(start_date(correspondence.received_date))
    end

    def external_deadline(correspondence)
      days_after_day_one = correspondence.category.external_time_limit - 1
      days_after_day_one.business_days.after(start_date(correspondence.received_date))
    end

    def start_date(received_date)
      date = received_date + 1
      date += 1 until date.workday?
      date
    end
  end

end
