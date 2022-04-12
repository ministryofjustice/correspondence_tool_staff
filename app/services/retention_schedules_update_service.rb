class RetentionSchedulesUpdateService

  attr_reader :error_message, 
              :result,
              :status_action

  STATUS_ACTIONS = {
    further_review_needed: 'review',
    retain: 'retain',
    mark_for_destruction: 'erasable',
    destroy_cases: 'erased'
  }.freeze

  def initialize(retention_schedules_params:, action_text:)
    @action_text = action_text
    @retention_schedules_params = retention_schedules_params
    @case_ids = prepare_case_ids
    @status_action = lookup_status_action 
    @result = :incomplete
    @error_message = nil
  end

  def call
    if @status_action.nil?
      @error_message =  "Requested retention schedule status action is incorrect"
      @result = :error
    else
      begin
        update_retention_schedule_statuses
      rescue StandardError => error
        @error_message = error.message
        @result = :error
      end
    end
  end

  def case_count
    @case_ids.size
  end

  def lookup_status_action
    STATUS_ACTIONS[parameterize_status_action]
  end

  def parameterize_status_action
    @action_text.parameterize(separator: "_").to_sym
  end

  def prepare_case_ids
    # check_boxes submit as { <case_id> => 1 } if selected
    # or { <case_id> => 0 } if not 
    @retention_schedules_params.to_h.filter_map do |key, value|
      key if value == "1"
    end
  end

  private

  def update_retention_schedule_statuses
    @case_ids.each do |case_id|
      kase = Case::Base.includes(:retention_schedule).find(case_id)
      if kase
        retention_schedule = kase.retention_schedule
        retention_schedule.status = @status_action
        retention_schedule.save if retention_schedule.valid? 
      end
    end
  end
end
