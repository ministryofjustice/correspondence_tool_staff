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
        message:,
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

private

  def message
    [
      "Old final deadline: #{I18n.localize(@case.external_deadline, format: :long)}",
      "New final deadline: #{I18n.localize(@case.original_external_deadline, format: :long)}",
    ].join("\n")
  end
end
