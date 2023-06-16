require "cts"

module CTS::Cases
  class Assign
    def initialize(kase, user, team, role, state = :accepted)
      @kase = kase
      @user = user
      @team = team
      @role = role
      @state = state
    end

    def call
      case @role
      when "managing"
        raise "approving assign not implemented yet"

      when "responding"
        @kase.responding_team = @team
        @kase.assign_responder(CTS.dacu_manager, @team)
        @kase.reload
        @kase.responder_assignment.accept(@user)

      when "approving"
        raise "approving assign not implemented yet"
      end
    end
  end
end
