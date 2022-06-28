module RetentionSchedules
  class AddScheduleService
    attr_reader :result

    def initialize(kase:, user:)
      @kase = kase
      @user = user
    end

    def call
      return if case_is_open

      ActiveRecord::Base.transaction do
        begin
          if @kase.offender_sar? || @kase.offender_sar_complaint?
            @planned_destruction_date = planned_destruction_date
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

    def case_is_open
      unless @kase.closed?
        @result = :invalid_as_case_is_open
        true
      end
    end

    def add_retention_schedules
      if @kase.linked_cases.present?
        add_retention_schedule
        if @kase.offender_sar_complaint?
          add_retention_schedules_to_linked_cases
        end
      else
        add_retention_schedule
      end
    end

    def add_retention_schedule(linked_case: nil)
      kase = linked_case.presence || @kase

      rs = RetentionSchedule.find_or_initialize_by(case: kase)
      rs.planned_destruction_date = @planned_destruction_date
      rs.save

      annotate_case!(
        kase, rs.saved_changes
      )

      kase.reload_retention_schedule
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

    def planned_destruction_date
      closure_date.advance(
        years: Settings.retention_timings.off_sars.erasure.years,
        months: Settings.retention_timings.off_sars.erasure.months
      )
    end

    def closure_date
      @kase.date_responded.presence || @kase.received_date
    end

    # This service class can also be called via a rake task to populate or update
    # the retention schedules for all cases in the database. This rake task does not
    # have the concept of an "user", so for the task runs we skip the annotations.
    # Refer to: `lib/tasks/retention_schedules.rake`
    def annotate_case!(kase, changes)
      return unless @user

      RetentionScheduleCaseNote.log!(
        kase: kase, user: @user, changes: changes, is_system: true
      )
    end
  end
end
