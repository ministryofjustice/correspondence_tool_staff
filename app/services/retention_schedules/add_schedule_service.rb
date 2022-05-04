module RetentionSchedules
  class AddScheduleService
    attr_reader :result

    def initialize(kase:)
      @kase = kase
      @planned_erasure_date = planned_erasure_date
      @result = nil
    end

    def call
      ActiveRecord::Base.transaction do
        begin
          if @kase.offender_sar? || @kase.offender_sar_complaint?
            add_retention_schedules
            @result = :success
          else
            @result = :invalid_case_type
          end
        rescue ActiveRecord::RecordInvalid => err
          Rails.logger.error err.to_s
          Rails.logger.error err.backtrace.join("\n\t")
          @result = :error
        end
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
        rs = kase.retention_schedule
        rs.planned_erasure_date = @planned_erasure_date 
        rs.save
      else
        kase.retention_schedule = RetentionSchedule.new(
          planned_erasure_date: @planned_erasure_date 
        )
      end
    end

    def add_retention_schedules_to_linked_cases
      processed_cases = []
      linked_cases = collect_linked_cases

      while linked_cases.present?
        current_case = linked_cases.shift
        if processed_cases.exclude?(current_case) && current_case.closed?
          add_retention_schedule(linked_case: current_case)
          processed_cases << current_case
        end
      end
    end

    def collect_linked_cases
      # i.e. is an offender sar complaint
      if @kase.original_cases.present?
       ([@kase.original_case] + 
        @kase.original_case.linked_cases).to_a
      else
        @kase.linked_cases.to_a
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
