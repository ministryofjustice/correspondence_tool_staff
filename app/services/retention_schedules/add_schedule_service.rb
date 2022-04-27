module RetentionSchedules
  class AddScheduleService
    attr_reader :result

    def initialize(kase:)
      @kase = kase
      @planned_erasure_date = planned_erasure_date
      @result = nil
    end

    def call
      if @kase.offender_sar?
        add_retention_schedule(@kase)
        return @kase
      elsif @kase.offender_sar_complaint?
        add_retention_schedule_for_cases_with_links(@kase)
        return @kase
      else
        @result = :invalid_case
        return @kase
      end
    end

    private

    def add_retention_schedule(kase)
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

    def add_retention_schedule_for_cases_with_links(kase)
      add_retention_schedule(kase)

      kase.linked_cases.each do |linked_kase|
        add_retention_schedule(linked_kase)
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
