module CaseStates
  extend ActiveSupport::Concern

  STATES_REQUIRING_CONFIGURABLE_STATE_MACHINE = [ nil, 'unassigned' ]

  included do
    after_update :reset_state_machine, if: :workflow_changed?
  end

  def state_machine
    if @state_machine.nil? || state_machine_of_wrong_type?
      if state_requires_configurable_state_machine?
        instantiate_configurable_state_machine
      else
        instantiate_legacy_state_machine
      end
    end
    @state_machine
  end

  def instantiate_configurable_state_machine
    @state_machine = ConfigurableStateMachine::Manager.instance.state_machine(org: 'moj',
                                                                              case_type: 'foi',
                                                                              workflow: workflow.nil? ? 'standard' : workflow,
                                                                              kase: self)
  end

  def instantiate_legacy_state_machine
    state_machine_class_name =
      if respond_to?(:workflow) && workflow.present?
        "Cases::#{category.abbreviation}::#{workflow}StateMachine"
      else
        "Cases::FOIStateMachine"
      end
    @state_machine = state_machine_class_name.constantize.new(
      self,
      transition_class: CaseTransition,
      association_name: :transitions
    )
  end


  def responder_assignment_rejected(current_user,
                                    responding_team,
                                    message)
    state_machine.reject_responder_assignment! current_user,
                                               responding_team,
                                               message
  end

  def responder_assignment_accepted(current_user, responding_team)
    state_machine.accept_responder_assignment!(current_user, responding_team)
  end

  def remove_response(current_user, attachment)
    attachment.destroy!
    state_machine.remove_response! current_user,
                                   responding_team,
                                   attachment.filename,
                                   self.reload.attachments.size
  end

  def response_attachments
    attachments.select(&:response?)
  end

  def respond(current_user)
    ActiveRecord::Base.transaction do
      state_machine.respond!(current_user)

      # pre-populate the date_responded field with the date the user
      # marked the case as sent
      self.update(date_responded: Date.today)
    end

  end

  def close(current_user)
    state_machine.close!(current_user)
  end

  private

  def state_machine_of_wrong_type?
    (current_state.in?(STATES_REQUIRING_CONFIGURABLE_STATE_MACHINE) && !@state_machine.configurable?) ||
      (!current_state.in?(STATES_REQUIRING_CONFIGURABLE_STATE_MACHINE) && @state_machine.configurable?)

  end

  def state_requires_configurable_state_machine?
    current_state.in?(STATES_REQUIRING_CONFIGURABLE_STATE_MACHINE)
  end

  def reset_state_machine
    @state_machine = nil
  end
end
