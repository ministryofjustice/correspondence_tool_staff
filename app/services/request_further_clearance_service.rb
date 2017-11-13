class RequestFurtherClearanceService

  attr_accessor :result

  def initialize(user:, kase:)
    @user = user
    @kase = kase
    @result = :incomplete
  end

  def call
    ActiveRecord::Base.transaction do
      #Flag it for Disclosure
      CaseFlagForClearanceService.new(user: @user,
                                    kase: @kase,
                                    team: BusinessUnit.dacu_disclosure).call

      # update the escalation deadline to the new clearance deadline
      # Enabled press/private to view this case in their Case list
      @kase.update( escalation_deadline: DeadlineCalculator.escalation_deadline(@kase, Date.today))

      #Add an entry in transitions table
      @kase.state_machine.request_further_clearance!(acting_user: @user,
                                         acting_team: @user.managing_teams.first,
                                         target_team: @kase.responding_team,
                                         target_user: @kase.responder)

      @result = :ok
    end

    @result
  rescue => err
    Rails.logger.error err.to_s
    Rails.logger.error err.backtrace.join("\n\t")
    @error = err
    @result = :error
  end
end
