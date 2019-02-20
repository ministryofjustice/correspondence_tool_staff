class CaseRemovePITExtensionService
  attr_reader :result, :error

  def initialize(user, kase)
    @user = user
    @case = kase
    @result = :incomplete
  end

  def call
    ActiveRecord::Base.transaction do
      @case.state_machine.remove_pit_extension!(
        acting_user: @user,
        acting_team: BusinessUnit.dacu_bmt
      )

      @case.remove_pit_deadline!(find_original_final_deadline)
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

  private

  def find_original_final_deadline
    first_pit_extension = @case.transitions
      .where(event: 'extend_for_pit')
      .order(:id)
      .first

    first_pit_extension.original_final_deadline
  end
end
