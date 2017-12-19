module CurrentTeamAndUser
  class SAR
    attr_reader :team, :user

    def initialize(kase)
      @case = kase
      @dts = DefaultTeamService.new(@case)
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
      @user = @case.approver_assignments.for_team(@team).first.user
    end

    def pending_press_office_clearance
      @team = BusinessUnit.press_office
      @user = @case.approver_assignments.for_team(@team).first.user
    end

    def pending_private_office_clearance
      @team = BusinessUnit.private_office
      @user = @case.approver_assignments.for_team(@team).first.user
    end

    def responded
      @team = @case.managing_team
      @user = nil
    end

    def closed
      @team = nil
      @user = nil
    end
  end
end
