class CaseDeletionService

  def initialize(user, kase, update_parameters)
    @user = user
    @kase = kase
    @update_parameters = update_parameters
  end

  # TODO - work out whether to catch all and log (which we forgot to do here)
  # or stay with this more idiomatic pattern (and maybe remove the transaction)
  def call
    ActiveRecord::Base.transaction do
      if @kase.update(@update_parameters.merge(deleted: true))
        @kase.state_machine.destroy_case!(acting_user: @user, acting_team: @kase.managing_team)
        :ok
      else
        :error
      end
    end
  end
end
