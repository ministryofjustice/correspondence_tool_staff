class DeadlineCalculator

  class << self
    def internal_deadline(correspondence)
      correspondence.category.internal_time_limit.business_days.after(start_date)
    end

    def external_deadline(correspondence)
      correspondence.category.external_time_limit.business_days.after(start_date)
    end

    def start_date
      date = Time.zone.today + 1
      date += 1 until date.workday?
      date
    end
  end

end
