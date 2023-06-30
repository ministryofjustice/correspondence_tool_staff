class CaseExtendForPITService
  attr_reader :result, :error

  def initialize(user, kase, extension_deadline, reason)
    @user = user
    @case = kase
    @extension_deadline = extension_deadline
    @reason = reason
    @result = :incomplete
  end

  def call
    ActiveRecord::Base.transaction do
      if validate_params
        @case.state_machine.extend_for_pit!(
          acting_user: @user,
          acting_team: @user.case_team(@case),
          final_deadline: @extension_deadline,
          original_final_deadline: @case.external_deadline,
          message: @reason,
        )

        @case.extend_pit_deadline!(@extension_deadline)
        @result = :ok
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

  def validate_params
    if @reason.blank?
      @case.errors.add(:reason_for_extending, "cannot be blank")
      @result = :validation_error
    end

    unless extension_date_valid?
      @result = :validation_error
    end

    @result = :ok if @case.errors.empty?
  end

  def extension_date_valid?
    extension_limit = Settings.pit_extension_limit
                        .business_days
                        .after(@case.external_deadline)
    if @extension_deadline.blank?
      @case.errors.add(:extension_deadline, "Date cannot be blank")
      false
    elsif @extension_deadline > extension_limit
      @case.errors.add(
        :extension_deadline,
        "Date is more than #{Settings.pit_extension_limit} beyond the final deadline",
      )
      false
    elsif @extension_deadline < @case.external_deadline
      @case.errors.add(:extension_deadline,
                       "Date cannot be before the final deadline")
      false
    else
      true
    end
  end
end
