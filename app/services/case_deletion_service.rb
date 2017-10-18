class CaseDeletionService

  attr_reader :result

  def initialize(user, kase)
    @user = user
    @team = kase.managing_team
    @kase = kase
    @result = :incomplete
  end

  def call
    ActiveRecord::Base.transaction do
      begin
        @kase.update(deleted?: true)
        @kase.state_machine.delete_case!(@user, @team)
        @result = :ok
      rescue
        @result = :error
      end
    end
  end

end
