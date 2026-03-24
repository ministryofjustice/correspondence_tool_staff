# This calculator is based on the rules from ICO for SAR case type
# - calender month for external deadline , extended external deadline (extension deadline)
# - if non-business-day, find the closest future working day
# Assumption
#  The time unit for calculating for external deadlines is all based on calendar month.
#  The current implementation does not handle if one type of deadline is based on days
#  but another type of deadline is basad on calendar month
# Proposal if such mixture of time units is required in the future
#  the configuration for limit can be changed to a string from integer and contains
#  the time unit as part of the string such as "30d" or "1m" etc,  the changes required
#  for such case mainly will be within this class or choosing to have a new class
#  and may consider to how to make the string contruction easier as well.

module DeadlineCalculator
  class CalendarMonths
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

    def days_after(number, date)
      date + number.days
    end

    def escalation_deadline
      kase.created_at.to_date + kase.correspondence_type.escalation_time_limit.days
    end

    def internal_deadline
      kase.received_date + kase.correspondence_type.internal_time_limit.days
    end

    def internal_deadline_for_date(correspondence_type, date)
      days = correspondence_type.internal_time_limit.days
      date + days
    end

    def external_deadline
      calculate_final_date_from_time_units(
        kase.correspondence_type.external_time_limit, kase.received_date
      )
    end

    def extension_deadline(time_limit)
      calculate_final_date_from_time_units(
        time_limit + kase.correspondence_type.external_time_limit, kase.received_date
      )
    end

    def business_unit_deadline_for_date(*)
      @kase.flagged? ? internal_deadline : external_deadline
    end

    def max_allowed_deadline_date(time_limit = nil)
      time_limit ||= kase.correspondence_type.extension_time_limit || 0
      calculate_final_date_from_time_units(
        time_limit + kase.correspondence_type.external_time_limit, kase.received_date
      )
    end

    def time_units_desc_for_deadline(time_limit = 1)
      "calendar #{'month'.pluralize(time_limit)}".freeze
    end

    def time_taken
      return nil if kase.date_responded.nil?

      days = (kase.date_responded - kase.received_date).to_i
      [days, 1].max
    end

  private

    def calculate_final_date_from_time_units(time_units, base_date)
      months_later = time_units.month.since(base_date)
      months_later = months_later.tomorrow until months_later.workday?
      months_later
    end
  end
end
