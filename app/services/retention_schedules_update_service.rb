class RetentionSchedulesUpdateService

  attr_reader :error_message, 
              :result,
              :post_update_message

  STATUS_ACTIONS = {
    further_review_needed: :mark_for_review,
    retain: :mark_for_retention,
    mark_for_destruction: :mark_for_anonymisation,
    destroy_cases: :anonymise!
  }.freeze

  POST_UPDATE_MESSAGES = {
    further_review_needed: "marked for review",
    retain: "marked for retention",
    mark_for_destruction: "marked for destruction",
    destroy_cases: "destroyed"
  }.freeze

  def initialize(retention_schedules_params:, event_text:, current_user:)
    @event_text = event_text
    @retention_schedules_params = retention_schedules_params
    @case_ids = prepare_case_ids
    @state_change_event = lookup_status_action 
    @post_update_message = lookup_post_update_message
    @result = :incomplete
    @current_user = current_user
    @error_message = nil
  end

  def call
    if @state_change_event.nil?
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

  def lookup_post_update_message
    POST_UPDATE_MESSAGES[parameterize_status_action]
  end

  def parameterize_status_action
    @event_text.parameterize(separator: "_").to_sym
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
    retention_schedules = RetentionSchedule
                            .includes(case: [
                              :assignments, 
                              :teams, 
                              :creator, 
                              :related_case_links, 
                              :related_cases, 
                              :case_links
                            ])
                            .where(case_id: @case_ids)

    retention_schedules.each do |retention_schedule|
      previous_state = retention_schedule.human_state
      retention_schedule.public_send(@state_change_event) do
        add_retention_schedule_state_change_note(
          kase: retention_schedule.case,
          previous_state: previous_state,
          current_state: retention_schedule.human_state
        )
      end
      retention_schedule.save if retention_schedule.valid? 
    end
  end

  def add_retention_schedule_state_change_note(kase:, previous_state:, current_state:)
    kase.state_machine.send(:add_note_to_case!,
      acting_user: @current_user,
      acting_team: @current_user.case_team(kase),
      message: "Case RRD status updated from #{previous_state} to #{current_state}"
    )
  end
end
