module RetentionSchedules
  class AddScheduleService
    attr_reader :result

    def initialize(kase:)
      @kase = kase
      @planned_erasure_date = planned_erasure_date
      @result = nil
    end

    def call
      if @kase.offender_sar? || @kase.offender_sar_complaint?
        add_retention_schedules
        return @kase
      else
        @result = :invalid_case
        return @kase
      end
    end

    private

    def add_retention_schedules
      if @kase.linked_cases.present?
        add_retention_schedule
        add_retention_schedules_to_linked_cases
      else
        add_retention_schedule
      end
    end

    def add_retention_schedule(linked_case: nil)
      kase = linked_case.present? ? linked_case : @kase
      if kase.retention_schedule.present?
        kase
          .retention_schedule
          .planned_erasure_date = @planned_erasure_date 
      else
        kase.retention_schedule = RetentionSchedule.new(
          planned_erasure_date: @planned_erasure_date 
        )
      end
    end

    def add_retention_schedules_to_linked_cases
      @kase.linked_cases.each do |linked_kase|
        add_retention_schedule(linked_case: linked_kase)
      end
    end

    def planned_erasure_date
      years = Settings.retention_timings.off_sars.erasure.years
      months = Settings.retention_timings.off_sars.erasure.months
      retention_period = years.years + months.months

      closure_date + retention_period + 1.day
    end

    def closure_date
      return @kase.last_transitioned_at.to_date if @kase.closed?
      nil
    end
  end
end
