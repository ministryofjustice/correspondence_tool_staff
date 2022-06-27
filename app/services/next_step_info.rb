class NextStepInfo

  attr_reader :kase, :action, :user, :next_state, :next_team, :action_verb

  def initialize(kase, action_param, user)
    @kase = kase
    @action = action_param
    @user = user
    @state_machine = @kase.state_machine
    translate_action_param(@action)
    @next_state = get_next_state
    @next_team = get_next_team
  end


  private

  def get_next_state
    @state_machine.next_state_for_event(@state_machine_event, acting_user_id: @user.id)
  rescue
    Rails.logger.error "Unexpected action #{@action} for case in #{@kase.current_state} state"
    raise
  end

  def get_next_team
    case @next_state
    when 'unassigned', 'responded', 'closed'
      'DACU'
    when 'awaiting_responder', 'drafting', 'awaiting_dispatch'
      @kase.responding_team
    when 'pending_dacu_clearance'
      BusinessUnit.dacu_disclosure
    when 'pending_press_office_clearance'
      BusinessUnit.press_office
    when 'pending_private_office_clearance'
      BusinessUnit.private_office
    else
      raise "Unexpected next state: #{@next_state}"
    end
  end

  def translate_action_param(action_param)
    case action_param
    when 'approve'
      @state_machine_event = :approve
      @action_verb = 'clearing the response to'
    when 'request-amends'
      @state_machine_event = :request_amends
      @action_verb = 'requesting amends for'
    when 'upload'
      @state_machine_event = :add_responses
      @action_verb = 'uploading changes to'
    when 'upload-flagged'
      @state_machine_event = :add_response_to_flagged_case
      @action_verb = 'uploading a response to'
    when 'upload-approve'
      @state_machine_event = :upload_response_and_approve
      @action_verb = 'uploading the responses and clearing'
    when 'upload-redraft'
      @state_machine_event = :upload_response_and_return_for_redraft
      @action_verb = 'uploading changes to'
    else
      raise "Unexpected action parameter: '#{@action}'"
    end
  end
  #rubocop:enable Metrics/CyclomaticComplexity
end
