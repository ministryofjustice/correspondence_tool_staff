module CaseStates
  extend ActiveSupport::Concern

  included do
    after_update :reset_state_machine, if: :workflow_changed?
  end

  def state_machine
    @state_machine ||= instantiate_configurable_state_machine
  end

  def instantiate_configurable_state_machine
    case_type = self.type_abbreviation.downcase
    @state_machine = ConfigurableStateMachine::Manager.instance.state_machine(
      org: 'moj',
      case_type: case_type,
      workflow: workflow.nil? ? 'standard' : workflow,
      kase: self
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
    # this isn't the right way of doing this
    teams = current_user.teams_for_case(self)

    weightings = { 'approver' => 200, 'responder' => 300 }
    team = teams.sort{ |a, b| weightings[a.role] <=> weightings[b.role] }.first

    # ActiveRecord::Base.transaction do
      state_machine.respond!(acting_user: current_user, acting_team: team)

      # pre-populate the date_responded field with the date the user
      # marked the case as sent
    # end

  end

  def close(current_user)
    state_machine.close!(acting_user: current_user, acting_team: self.managing_team)
  end

  private

  def reset_state_machine
    @state_machine = nil
  end
end
