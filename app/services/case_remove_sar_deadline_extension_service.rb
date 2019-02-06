class CaseRemoveSARDeadlineExtensionService
  attr_reader :result, :error

  def initialize(user, kase)
    @user = user
    @case = kase
    @result = :incomplete
  end

  def call
    ActiveRecord::Base.transaction do
      @case.state_machine.remove_extended_deadline_for_sar!(
        acting_user: @user,
        acting_team: @user.team_for_case(@case)
      )

      @case.reset_deadline!
      @result = :ok
    end
    @result
  rescue => err
    Rails.logger.error err.to_s
    Rails.logger.error err.backtrace.join("\n\t")
    @error = err
    @result = :error
    raise err
  end
end
