module DataRequestCalculator
  class Standard
    attr_reader :data_request_area, :start

    CHASE_INTERVAL = 4
    ESCALATION_AFTER = 2

    def initialize(data_request_area, start)
      @data_request_area = data_request_area
      @start = start.to_date
    end

    def deadline_days
      5
    end

    def deadline
      start + deadline_days.days
    end

    def next_chase_date
      return nil if data_request_area.kase.closed?

      if last_email_date.present? && last_email_date >= first_chase_date
        last_email_date + CHASE_INTERVAL.days
      else
        [Date.current, first_chase_date].max
      end
    end

    def next_chase_type
      return nil if next_chase_date.nil?

      if next_chase_date > data_request_area.kase.external_deadline
        DataRequestChase::OVERDUE_CHASE
      elsif next_chase_date >= first_escalation_date
        DataRequestChase::ESCALATION_CHASE
      else
        DataRequestChase::STANDARD_CHASE
      end
    end

  private

    def first_chase_date
      deadline + 1.day
    end

    def first_escalation_date
      first_chase_date + (ESCALATION_AFTER * CHASE_INTERVAL).days
    end

    def last_email_date
      data_request_area.data_request_emails.maximum(:created_at)&.to_date
    end
  end
end
