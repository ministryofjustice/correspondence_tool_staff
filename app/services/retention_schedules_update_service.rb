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
      @error_message = "Requested retention schedule status action is incorrect"
      @result = :error
    else
      begin
        if @state_change_event == :anonymise!
          anonymise_cases
        else
          update_retention_schedule_statuses
        end
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

  def anonymise_cases
    kases = Case::SAR::Offender
      .includes([
        :assignments, 
        :transitions,
        :data_requests,
        :versions
      ]).where(id: @case_ids)

    kases.each do |kase|
      service = RetentionSchedules::AnonymiseCaseService.new(
        kase: kase
      )
      service.call
    end
  end

  def update_retention_schedule_statuses
    retention_schedules = RetentionSchedule
      .includes(case: [
        :assignments, 
        :teams, 
        :creator, 
        :related_case_links, 
        :related_cases, 
        :case_links
      ]).where(case_id: @case_ids)
    retention_schedules.each do |retention_schedule|
      retention_schedule.public_send(@state_change_event)

      if retention_schedule.valid?
        retention_schedule.save

        annotate_case!(
          retention_schedule.case,
          retention_schedule.saved_changes
        )
      end
    end

  end

  def annotate_case!(kase, changes)
    RetentionScheduleCaseNote.log!(
      kase: kase, user: @current_user, changes: changes
    )
  end
end
