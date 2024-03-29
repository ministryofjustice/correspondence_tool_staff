class CaseRemoveSARDeadlineExtensionService
  attr_reader :result, :error

  def initialize(user, kase)
    @user = user
    @case = kase
    @result = :incomplete
  end

  def call
    ActiveRecord::Base.transaction do
      @case.state_machine.remove_sar_deadline_extension!(
        acting_user: @user,
        acting_team: @user.case_team(@case),
      )

      @case.reset_deadline!
      @result = :ok
    end
    @result
  rescue StandardError => e
    Rails.logger.error e.to_s
    Rails.logger.error e.backtrace.join("\n\t")
    @error = e
    @result = :error
  end
end
