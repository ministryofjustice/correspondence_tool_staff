module DataRequestCalculator
  class Standard
    attr_reader :data_request_area, :start

    CHASE_INTERVAL = 4
    ESCALATION_AFTER = 2

    STANDARD_CHASE = :chase_email
    ESCALATION_CHASE = :chase_escalation_email
    OVERDUE_CHASE = :chase_overdue_email

    def initialize(data_request_area, start)
      @data_request_area = data_request_area
      @start = start
    end

    def deadline_days
      5
    end

    def deadline
      start + deadline_days.days
    end

    def next_chase_date
      return nil if data_request_area.kase.closed?

      if last_email.present? && last_email >= first_chase
        last_email + CHASE_INTERVAL.days
      else
        [Date.current, first_chase].max
      end
    end

    def next_chase_type
      return nil if next_chase_date.nil?

      if next_chase_date > data_request_area.kase.external_deadline
        OVERDUE_CHASE
      elsif next_chase_date >= first_escalation
        ESCALATION_CHASE
      else
        STANDARD_CHASE
      end
    end

  private

    def first_chase
      deadline + 1.day
    end

    def first_escalation
      first_chase + (ESCALATION_AFTER * CHASE_INTERVAL)
    end

    def last_email
      data_request_area.data_request_emails.maximum(:created_at)&.to_date
    end
  end
end
