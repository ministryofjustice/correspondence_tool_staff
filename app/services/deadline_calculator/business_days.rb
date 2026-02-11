module DeadlineCalculator
  class BusinessDays
    attr_reader :kase

    def initialize(kase)
      @kase = kase
    end

    def days_taken(start_date, end_date)
      start_date.business_days_until(end_date, true, options)
    end

    def days_late(start_date, end_date)
      start_date.business_days_until(end_date, false, options)
    end

    def days_before(number, date)
      number.business_days.before(date, options)
    end

    def days_after(number, date)
      number.business_days.after(date, options)
    end

    def escalation_deadline(start_from = kase.created_at.to_date)
      start = next_working_day(start_from)
      calculate(kase.correspondence_type.escalation_time_limit, start)
    end

    # aka draft deadline
    def internal_deadline
      internal_deadline_for_date(kase.correspondence_type)
    end

    def internal_deadline_for_date(correspondence_type, date = nil)
      calculate(correspondence_type.internal_time_limit, date)
    end

    # aka final deadline
    def external_deadline
      external_deadline_for_date(kase.correspondence_type)
    end

    def business_unit_deadline_for_date(date)
      if kase.flagged?
        internal_deadline_for_date(kase.correspondence_type, date.to_date)
      else
        external_deadline_for_date(kase.correspondence_type, date.to_date)
      end
    end

    def extension_deadline(time_limit)
      calculate(kase.correspondence_type.external_time_limit + time_limit)
    end

    def max_allowed_deadline_date(time_limit = nil)
      time_limit ||= kase.correspondence_type.extension_time_limit || 0
      extension_deadline(time_limit)
    end

    def time_units_desc_for_deadline(time_limit = 1)
      "business #{'day'.pluralize(time_limit)}".freeze
    end

    def time_taken
      return nil if kase.date_responded.nil?

      days_taken(kase.received_date, kase.date_responded)
    end

  private

    def calculate(days, from = nil)
      from ||= next_working_day(kase.received_date)
      (days - 1).business_days.after(from, options)
    end

    def next_working_day(date)
      new_date = date + 1
      new_date += 1 until new_date.workday?(options)
      new_date
    end

    def external_deadline_for_date(correspondence_type, date = nil)
      calculate(correspondence_type.external_time_limit, date)
    end

    def options
      kase.all_holidays? ? { holidays: ::BusinessTimeConfig.additional_bank_holidays } : {}
    end
  end
end
