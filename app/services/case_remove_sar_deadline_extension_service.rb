class CaseRemoveSARDeadlineExtensionService
  attr_reader :result, :error

  def initialize(user, kase, reason: nil)
    @user = user
    @case = CaseRemoveSARDeadlineExtensionDecorator.decorate kase
    @reason = reason
    @result = :incomplete
  end

  def call
    ActiveRecord::Base.transaction do
      if valid?
        @case.state_machine.remove_sar_deadline_extension!(
          acting_user: @user,
          acting_team: @user.case_team(@case),
          message:,
        )

        @case.reset_deadline!
        @result = :ok
      else
        @result = :validation_error
      end
    end
    @result
  rescue StandardError => e
    Rails.logger.error e.to_s
    Rails.logger.error e.backtrace.join("\n\t")
    @error = e
    @result = :error
  end

private

  def valid?
    if @reason.blank?
      @case.errors.add(
        :reason_for_removing_extension,
        "cannot be blank",
      )
    end

    @case.errors.empty?
  end

  def message
    [
      "Old final deadline: #{I18n.localize(@case.external_deadline, format: :long)}",
      "New final deadline: #{I18n.localize(@case.recalculate_deadline_without_extensions, format: :long)}",
      "Reason: #{@reason}",
    ].join("\n")
  end
end
