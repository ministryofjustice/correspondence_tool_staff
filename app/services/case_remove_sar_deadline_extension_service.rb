class CaseRemoveSARDeadlineExtensionService
  attr_reader :result, :error

  def initialize(user, kase)
    @user = user
    @case = kase
    @result = :incomplete
  end

  def call
    ActiveRecord::Base.transaction do
      # @case.state_machine.remove_pit_extension!(acting_user: @user,
      #                                           acting_team: BusinessUnit.dacu_bmt)
      @case.update external_deadline: (find_original_final_deadline)
      @case.reload
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

  # TODO (Mohammed Seedat): Set original deadline date from transitions
  def find_original_final_deadline
    DateTime.now
    # first_sar_extension = @case.transitions.where(event: 'extend_deadline_for_sar')
    #                             .order(:id)
    #                             .first
    # first_sar_extension.original_final_deadline
  end
end
