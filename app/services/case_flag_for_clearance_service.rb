class CaseFlagForClearanceService
  attr_accessor :result, :other_user

  def initialize(user:, kase:, team: nil)
    @case = kase
    @user = user
    @team = team
    @result = :incomplete
    @dts = DefaultTeamService.new(kase)
  end

  def call
    return @result unless validate_case_is_unflagged

    ActiveRecord::Base.transaction do
      if @team.dacu_disclosure?
        assign_approver acting_user: @user,
                        acting_team: @dts.managing_team,
                        target_team: @team

      elsif @team.press_office? || @team.private_office?
        assign_and_accept_approver acting_user: @user, acting_team: @team,
                                   target_team: @team
        @dts.associated_teams(for_team: @team).each do |associated|
          associate_team(associated[:team], associated[:user])
        end
      end
    end

    @result = :ok
  end

private

  def validate_case_is_unflagged
    if @case.approving_teams.exclude?(@team)
      true
    else
      @result = :already_flagged
      @other_user = @case.approver_assignments.for_team(@team).first.user
      false
    end
  end

  def assign_approver(acting_user:, acting_team:, target_team:)
    @case.state_machine.flag_for_clearance!(acting_user:,
                                            acting_team:,
                                            target_team:)

    @case.approving_teams << target_team
  end

  def assign_and_accept_approver(acting_user:, acting_team:, target_team:)
    @case.state_machine.take_on_for_approval!(acting_user:,
                                              acting_team:,
                                              target_team:)
    @case.approving_teams << target_team
    @case.reload
    team_assignment = @case.approver_assignments.for_team(target_team).last
    team_assignment.update!(state: "accepted", user_id: acting_user.id)
  end

  def associate_team(associate_team, associate_user)
    if @case.approver_assignments.where(team: associate_team).blank?
      if associate_user
        assign_and_accept_approver target_team: associate_team,
                                   acting_user: associate_user,
                                   acting_team: @team
      else
        assign_approver acting_user: @user, acting_team: @team,
                        target_team: associate_team
      end
    end
  end
end
