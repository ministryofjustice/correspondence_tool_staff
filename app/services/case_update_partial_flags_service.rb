class CaseUpdatePartialFlagsService
  attr_accessor :result, :message

  def initialize(user:, kase:, flag_params:)
    @case = kase
    @user = user
    @flag_params = flag_params
    @message = nil
    @result = :incomplete
  end

  def call
    ActiveRecord::Base.transaction do
      @case.assign_attributes(@flag_params)
      has_changed = is_data_changed?
      has_partial_flag_changed = is_partial_case_flag_changed?
      has_second_flag_changed = is_further_actions_required_flag_changed?
     
      if has_partial_flag_changed
        trigger_event(get_partial_event_name('mark_as_partial_case', @flag_params["is_partial_case"]))
      end 

      if has_second_flag_changed
        trigger_event(get_event_name_for_second_flag(@flag_params["further_actions_required"]))        
      end
      
      if has_changed
        @case.save!
        @result = :ok
      else
        @result = :no_changes
      end
    end
  rescue
    @result = :error
  end

  private 

  def is_partial_case_flag_changed?
    @case.changed_attributes.keys.include?('is_partial_case')
  end

  def is_further_actions_required_flag_changed?
    @case.changed_attributes.keys.include?('further_actions_required')
  end

  def is_date_change?
    @case.changed_attributes.keys.include?('partial_case_letter_sent_dated')
  end
  
  def is_data_changed?
    is_partial_case_flag_changed? || is_further_actions_required_flag_changed? || is_date_change?
  end

  def get_partial_event_name(event_name, flag_value)
    if flag_value.to_s.downcase == "true"
      event_name
    else
      "un#{event_name}"
    end
  end

  def get_event_name_for_second_flag(flag_value)
    case flag_value
    when 'yes'
      'mark_as_further_actions_required'
    when 'no'
      'unmark_as_further_actions_required'
    when 'awaiting_response'
      'mark_as_awaiting_response_for_partial_case'
    end
  end

  def trigger_event(event_name)
    acting_team = @user.case_team_for_event(@case, event_name)
    @case.state_machine.send("#{event_name}!", acting_user: @user,
      acting_team: acting_team)
  end
end
