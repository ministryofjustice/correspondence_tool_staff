class CaseReopenService
  attr_reader :result

  def initialize(user, kase, update_parameters)
    @user = user
    @kase = kase
    @update_parameters = update_parameters
    @result = :incomplete
  end

  def call
    begin
      @kase.state_machine.reopen!(
        acting_user: @user,
        acting_team: @user.case_team(@kase),
      )
      @result = if @kase.update(@update_parameters.merge(date_responded: nil))
                  :ok
                else
                  :error
                end
    rescue InvalidEventError => e
      @kase.errors.add(:external_deadline, e.message)
      @result = :error
    end

    @result
  end
end
