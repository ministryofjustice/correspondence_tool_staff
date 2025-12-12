module CurrentTeamAndUser
  class Base
    attr_reader :team, :user

    def initialize(kase)
      @case = kase
      @dts = DefaultTeamService.new(@case)
      @team = nil
      @user = nil
    end

    # use method missing to get default value when the case type doesn't implement state-method
    def method_missing(method_name, *args) # rubocop:disable Style/MissingRespondToMissing
      super unless @case.class.permitted_states.include?(method_name.to_s) && !respond_to?(method_name.to_s)
    end

    def unassigned
      @team = @case.managing_team
      @user = nil
    end

    def awaiting_responder
      @team = @case.responding_team
      @user = nil
    end

    def drafting
      @team = @case.responding_team
      @user = @case.responder
    end

    def awaiting_dispatch
      @team = @case.responding_team
      @user = @case.responder
    end

    def pending_dacu_clearance
      @team = @dts.approving_team
      @user = @case.approver_assignments.for_team(@team).first&.user
    end

    def pending_press_office_clearance
      @team = BusinessUnit.press_office
      @user = @case.approver_assignments.for_team(@team).first&.user
    end

    def pending_private_office_clearance
      @team = BusinessUnit.private_office
      @user = @case.approver_assignments.for_team(@team).first&.user
    end

    def responded
      @team = @case.managing_team
      @user = nil
    end

    def stopped
      previous_state = @case.last_stop_the_clock_transition&.details&.fetch("last_status", nil)

      if previous_state
        self.__send__(previous_state)
      else
        @team = @case.managing_team
        @user = nil
      end
    end

    def closed
      @team = nil
      @user = nil
    end
  end
end
