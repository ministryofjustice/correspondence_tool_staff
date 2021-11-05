class CaseUpdatePartialFlagsService
  attr_accessor :result, :message, :transitions

  def initialize(user:, kase:, flag_params:)
    @case = kase
    @user = user
    @flag_params = flag_params
    @message = nil
    @transitions = []
    @result = :incomplete
  end

  def call
    ActiveRecord::Base.transaction do
      set_initial_value
      update_flag_of_requiring_further_actions(@flag_params['further_actions_required'])
      update_partial_flag(@flag_params['is_partial_case'])
      update_case_with_new_flags
      @result = :ok
    end
  rescue
    @result = :error
    raise
  end

  private 

  def update_case_with_new_flags
    @case.save!
  end

  def set_initial_value
    if @case.is_partial_case.nil?
      @case.is_partial_case = false
      @case.save!
    end
    if @case.further_actions_required.nil?
      @case.further_actions_required = false
      @case.save!
    end
  end

  def update_partial_flag(is_partial_case)
    @case.is_partial_case =  is_partial_case unless is_partial_case.blank? 
    if is_partial_case_flag_changed?
      trigger_event(get_event_name('mark_as_partial_case', is_partial_case))
    end
  end

  def update_flag_of_requiring_further_actions(further_actions_required)
    @case.further_actions_required = further_actions_required unless further_actions_required.blank? 
    if is_further_actions_required_flag_changed?
      trigger_event(get_event_name('mark_as_further_actions_required', further_actions_required))
    end
  end

  def is_partial_case_flag_changed?
    @case.changed_attributes.keys.include?('is_partial_case')
  end

  def is_further_actions_required_flag_changed?
    @case.changed_attributes.keys.include?('further_actions_required')
  end

  def get_event_name(event_name, flag_value)
    if flag_value.to_s.downcase == "true"
      event_name
    else
      "un#{event_name}"
    end
  end

  def trigger_event(event_name)
    acting_team = @user.case_team_for_event(@case, event_name)
    @case.state_machine.send("#{event_name}!", acting_user: @user,
      acting_team: acting_team)
    new_transition = @case.reload.transitions.last
    transitions << {
      timestamp: new_transition.decorate.action_date,
      user: @user.full_name, 
      team: acting_team.name, 
      message: new_transition.decorate.event_and_detail
    }
  end
end
