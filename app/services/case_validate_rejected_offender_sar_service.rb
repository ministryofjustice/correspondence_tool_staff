class CaseValidateRejectedOffenderSARService
  attr_reader :result, :error_message

  def initialize(user:, kase:, params:)
    @user = user
    @case = kase
    @params = params
    @result = :incomplete
    @error_message = nil
  end

  def call(message = nil)
    ActiveRecord::Base.transaction do
      @case.assign_attributes(@params)
      @case.set_valid_case_number
      # Ensure external deadline is updated
      @case.external_deadline = @case.deadline_calculator.external_deadline
      @case.save!
      @case.state_machine.validate_rejected_case!(
        {
          acting_user: @user,
          acting_team: @user.case_team(@case),
          message:,
        },
      )
      @result = :ok
    end
    @result
  rescue StandardError => e
    @error_message = e.message
    @result = :error
  end
end
