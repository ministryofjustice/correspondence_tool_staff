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
        # properties is JSON object, if one of keys was not included 
        # but later this key with value of nil is added, 
        # it will be treated as changed which will give a misleading message 
        # as from user's point of view, he/she doesn't change anything
        # Each key within this JSON object will be tracked individually, 
        # no need for tracking properties as the whole.
        if (@kase.changed_attributes.keys - ["properties"]).present?
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
