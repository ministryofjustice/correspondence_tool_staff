# This calculator is based on the rules for ICO
# - calender month 
# - if non-business-day, find the closet future working day

module DeadlineCalculator
    class CalendarMonth
  
      attr_reader :kase
  
      def initialize(kase)
        @kase = kase
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
        month_later = 1.month.since(kase.received_date)
        while !month_later.workday? || month_later.bank_holiday?
          month_later = month_later.tomorrow
        end
        month_later
      end
  
      def business_unit_deadline_for_date(date=nil)
        deadline_method  = @kase.flagged? ? internal_deadline : external_deadline
      end
    end
  end
  