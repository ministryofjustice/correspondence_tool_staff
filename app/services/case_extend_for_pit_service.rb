class CaseExtendForPITService
  attr_reader :result, :error

  def initialize(user, kase, new_deadline, reason)
    @user = user
    @case = kase
    @new_deadline = new_deadline
    @reason = reason
    @result = :incomplete
  end

  def call
    ActiveRecord::Base.transaction do
      @case.state_machine.extend_for_pit! @user, @new_deadline, @reason
      @case.update! external_deadline: @new_deadline
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
