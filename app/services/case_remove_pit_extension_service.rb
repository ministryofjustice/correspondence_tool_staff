class CaseRemovePITExtensionService
  attr_reader :result, :error

  def initialize(user, kase)
    @user = user
    @case = kase
    @result = :incomplete
  end

  def call
    ActiveRecord::Base.transaction do
      @case.state_machine.remove_pit_extension!(acting_user: @user,
                                                acting_team: BusinessUnit.dacu_bmt)
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
  end

  private

  def find_original_final_deadline
    first_pit_extension = @case.transitions.where(event: 'extend_for_pit')
                                .reorder(:created_at)
                                .first
    first_pit_extension.original_final_deadline
  end
end
