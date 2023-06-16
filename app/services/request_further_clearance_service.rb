class RequestFurtherClearanceService
  attr_accessor :result

  def initialize(user:, kase:)
    @user = user
    @kase = kase
    @result = :incomplete
  end

  def call
    ActiveRecord::Base.transaction do
      # Add an entry in transitions table
      #
      # The state transition is done before the approver assignment is made
      # because the state machine checks to make sure the case isn't already
      # flagged (as part of validating what state the case is in). If done the
      # other way around, this state transition will fail and this transaction
      # will be aborted.
      #
      # The target_team info is used when displaying who requested further
      # clearance.
      @kase.state_machine.request_further_clearance!(
        acting_user: @user,
        acting_team: @user.managing_teams.first,
        target_team: responding_team_if_case_accepted,
        target_user: @kase.responder,
      )

      flag_case_for_disclosure

      flag_case_for_press_and_private if @kase.foi?

      @result = :ok
    end

    @result
  rescue StandardError => e
    Rails.logger.error e.to_s
    Rails.logger.error e.backtrace.join("\n\t")
    @error = e
    @result = :error
  end

private

  def responding_team_if_case_accepted
    if @kase.responder.nil?
      nil
    else
      @kase.responding_team
    end
  end

  def flag_case_for_disclosure
    CaseFlagForClearanceService.new(user: @user,
                                    kase: @kase,
                                    team: BusinessUnit.dacu_disclosure).call
  end

  def flag_case_for_press_and_private
    # update the escalation deadline to the new clearance deadline
    # Enabled press/private to view this case in their Case list
    @kase.update(escalation_deadline: @kase.deadline_calculator.escalation_deadline(Time.zone.today))
  end
end
