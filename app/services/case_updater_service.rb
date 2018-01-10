class CaseUpdaterService

  attr_reader :result

  def initialize(user, kase, params)
    @user = user
    @team = kase.managing_team
    @kase = kase
    @params = params
    @result = :incomplete
  end

  def call
    ActiveRecord::Base.transaction do
      begin
        @kase.assign_attributes(@params)
        if @kase.changed?
          @kase.save!
          @kase.state_machine.edit_case!(acting_user: @user, acting_team: @team)
          @result = :ok
        else
          @result = :no_changes
        end
      rescue
        @result = :error
      end

    end
  end

end
