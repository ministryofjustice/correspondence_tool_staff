class NextStepInfo

  attr_reader :kase, :action, :next_state, :next_team, :action_verb

  def initialize(kase, action_param)
    @kase = kase
    @action = action_param
    @state_machine = @kase.state_machine
    translate_action_param(@action)
    @next_state = get_next_state
    @next_team = get_next_team
  end


  private

  def get_next_state
    transitions = @state_machine.class.events[@state_machine_event][:transitions]
    target_states = transitions[@kase.current_state]
    if target_states.nil?
      raise "Unexpected action #{@action} for case in #{@kase.current_state} state"
    end
    target_states.first
  end

  def get_next_team
    case @next_state
    when 'unassigned', 'responded', 'closed'
      'DACU'
    when 'awaiting_responder', 'drafting', 'awaiting_dispatch'
      @kase.responding_team
    when 'pending_dacu_clearance'
      Team.dacu_disclosure
    else
      raise "Unexpected next state: #{@next_state}"
    end
  end

  def translate_action_param(action_param)
    case action_param
    when 'approve'
      @state_machine_event = :approve
      @action_verb = 'approving the case'
    when 'upload'
      @state_machine_event = :add_responses
      @action_verb = 'uploading responses to the case'
    when 'upload-flagged'
      @state_machine_event = :add_response_to_flagged_case
      @action_verb = 'uploading responses to the flagged case'
    when 'upload-approve'
      @state_machine_event = :upload_response_and_approve
      @action_verb = 'uploading responses and clearing the case'
    when 'upload-revert'
      @state_machine_event = :upload_response_and_return_for_redraft
      @action_verb = 'uploading responses and returning to KILO for redraft for the case'
    else
      raise "Unexpected action parameter: '#{@action}'"
    end
  end
end
