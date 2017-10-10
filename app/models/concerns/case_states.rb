module CaseStates
  extend ActiveSupport::Concern

  included do
    after_update :reset_state_machine, if: :workflow_changed?
  end

  def state_machine
    if @state_machine.nil?
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
    @state_machine
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
      state_machine.respond!(current_user, responding_team)

      # pre-populate the date_responded field with the date the user
      # marked the case as sent
      self.update(date_responded: Date.today)
    end

  end

  def close(current_user)
    state_machine.close!(current_user, managing_team)
  end

  private

  def reset_state_machine
    @state_machine = nil
  end
end
