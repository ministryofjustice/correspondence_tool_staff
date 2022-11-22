module DeadlineCalculator
  class BusinessDays
    attr_reader :kase

    class << self

      def days_taken(start_date, end_date)
        start_date.business_days_until(end_date, true)
      end

      def days_late(start_date, end_date)
        start_date.business_days_until(end_date, false)
      end

    end

    def initialize(kase)
      @kase = kase
    end

    def internal_deadline # aka draft deadline
      internal_deadline_for_date(kase.correspondence_type)
    end

    def external_deadline # aka final deadline
      external_deadline_for_date(kase.correspondence_type)
    end

    def extension_deadline(time_limit)
      calculate(kase.correspondence_type.external_time_limit + time_limit)
    end

    def escalation_deadline(start_from=kase.created_at.to_date)
      start = start_date(start_from)
      calculate(kase.correspondence_type.escalation_time_limit, start)
    end

    def business_unit_deadline_for_date(date)
      if kase.flagged?
        internal_deadline_for_date(kase.correspondence_type, date.to_date)
      else
        external_deadline_for_date(kase.correspondence_type, date.to_date)
      end
    end

    def internal_deadline_for_date(correspondence_type, date=nil)
      calculate(correspondence_type.internal_time_limit, date)
    end

    def external_deadline_for_date(correspondence_type, date=nil)
      calculate(correspondence_type.external_time_limit, date)
    end

    def max_allowed_deadline_date(time_limit=nil)
      time_limit ||= kase.correspondence_type.extension_time_limit || 0
      extension_deadline(time_limit)
    end

    def time_units_desc_for_deadline(time_limit=1)
      "business #{'day'.pluralize(time_limit)}".freeze
    end

    private

    def calculate(days, from=nil)
      from ||= start_date(kase.received_date)
      (days - 1).business_days.after(from)
    end

    def start_date(received_date)
      actual_received_date = received_date
      actual_received_date += 1 until actual_received_date.workday?
      date = actual_received_date + 1
      date += 1 until date.workday?
      date
    end
  end
end
