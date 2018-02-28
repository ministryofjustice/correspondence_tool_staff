module CaseStates
  extend ActiveSupport::Concern

  TRIGGER_STATES_REQUIRING_CONFIGURABLE_STATE_MACHINE = [ nil, 'unassigned' ]
  NON_TRIGGER_STATES_REQUIRING_CONFIGURABLE_STATE_MACHINE = [ nil,
                                                              'unassigned',
                                                              'awaiting_responder',
                                                              'drafting',
                                                              'awaiting_dispatch',
                                                              'responded']

  included do
    after_update :reset_state_machine, if: :workflow_changed?
  end

  def state_machine
    desired_state_machine_class = state_machine_class
    if @state_machine.class != desired_state_machine_class
      instantiate_state_machine(desired_state_machine_class)
    end
    @state_machine
  end

  def instantiate_state_machine(klass)
    if klass == ConfigurableStateMachine::Machine
      instantiate_configurable_state_machine
    else
      instantiate_legacy_state_machine
    end
  end

  def instantiate_configurable_state_machine
    case_type = if self.is_a?(Case::FOI::Standard)
                  'foi'
                else
                  'sar'
                end
    @state_machine = ConfigurableStateMachine::Manager.instance.state_machine(org: 'moj',
                                                                              case_type: case_type,
                                                                              workflow: workflow.nil? ? 'standard' : workflow,
                                                                              kase: self)
  end

  def instantiate_legacy_state_machine
    @state_machine = Case::FOI::StandardStateMachine.new(
      self,
      transition_class: CaseTransition,
      association_name: :transitions
    )
  end


  def responder_assignment_rejected(current_user,
                                    responding_team,
                                    message)
    state_machine.reject_responder_assignment! acting_user: current_user,
                                               acting_team: responding_team,
                                               message: message
  end

  def responder_assignment_accepted(current_user, responding_team)
    state_machine.accept_responder_assignment!(acting_user: current_user, acting_team: responding_team)
  end

  def remove_response(current_user, attachment)
    attachment.destroy!
    state_machine.remove_response! acting_user: current_user,
                                   acting_team: responding_team,
                                   filenames: attachment.filename,
                                   num_attachments: self.reload.attachments.size
  end

  def response_attachments
    attachments.select(&:response?)
  end

  def respond(current_user)
    ActiveRecord::Base.transaction do
      state_machine.respond!(acting_user: current_user, acting_team: self.responding_team)

      # pre-populate the date_responded field with the date the user
      # marked the case as sent
      self.update(date_responded: Date.today)
    end

  end

  def close(current_user)
    state_machine.close!(acting_user: current_user, acting_team: self.managing_team)
  end

  private

  def state_machine_class
    if self.type_abbreviation == 'SAR'
      ConfigurableStateMachine::Machine
    else
      configurable_states = workflow == 'trigger' ? TRIGGER_STATES_REQUIRING_CONFIGURABLE_STATE_MACHINE : NON_TRIGGER_STATES_REQUIRING_CONFIGURABLE_STATE_MACHINE
      if current_state.in?(configurable_states)
        ConfigurableStateMachine::Machine
      else
        Case::FOI::StandardStateMachine
      end
    end
  end

  def reset_state_machine
    @state_machine = nil
  end
end
