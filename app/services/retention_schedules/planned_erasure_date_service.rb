module RetentionSchedules
  class PlannedErasureDateService
    attr_reader :result

    def initialize(kase:)
      @kase = kase
      @planned_erasure_date = planned_erasure_date
      @result = nil
    end

    def call
      if @kase.offender_sar?
        calculate_off_sar_planned_erasure_dates
        return @kase
      else
        @result = :invalid_case
        return @kase
      end
    end

    private

    def calculate_off_sar_planned_erasure_dates
      if @kase.retention_schedule.present?
        @kase
          .retention_schedule
          .planned_erasure_date = @planned_erasure_date 
      else
        @kase.retention_schedule = RetentionSchedule.new(
          planned_erasure_date: @planned_erasure_date 
        )
      end
      @kase
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
