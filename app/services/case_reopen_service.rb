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
        acting_team: @user.case_team(@kase)
      )
      if @kase.update(@update_parameters.merge(date_responded: nil))
        @result = :ok
      else
        @result = :error
      end
    rescue InvalidEventError => err
      @kase.errors.add(:external_deadline, err.message)
      @result = :error
    end

    @result
  end

end

