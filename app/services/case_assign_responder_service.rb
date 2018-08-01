class CaseAssignResponderService
  attr_reader :result, :assignment

  def initialize(team:, kase:, role:, user:)
    @team = team
    @case = kase
    @role = role
    @user = user
    @result = :incomplete
  end

  def call
    Assignment.connection.transaction do
      puts ">>>>>>>>>> preparing assingment and email #{__FILE__}:#{__LINE__} <<<<<<<<<<"
      Rails.logger.debug ">>>>>>>>>> preparing assingment and email #{__FILE__}:#{__LINE__} <<<<<<<<<<"
      @assignment = @case.assignments.new(team: @team, role: @role)
      if @assignment.valid?
        managing_team = @user.managing_teams.first
        @case.state_machine.assign_responder! acting_user: @user, acting_team: managing_team, target_team: @team
        @assignment.save
        @result = :ok
        puts ">>>>>>>>>> OK #{__FILE__}:#{__LINE__} <<<<<<<<<<"
        Rails.logger.debug ">>>>>>>>>> OK #{__FILE__}:#{__LINE__} <<<<<<<<<<"
      else
        @result = :could_not_create_assignment
        puts ">>>>>>>>>> ERROR #{__FILE__}:#{__LINE__} <<<<<<<<<<"
        Rails.logger.debug ">>>>>>>>>> ERROR #{__FILE__}:#{__LINE__} <<<<<<<<<<"
      end
    end
    if @result == :ok
      puts ">>>>>>>>>> sending mail #{__FILE__}:#{__LINE__} <<<<<<<<<<"
      Rails.logger.debug ">>>>>>>>>> sending mail #{__FILE__}:#{__LINE__} <<<<<<<<<<"
      NotifyNewAssignmentService.new(team: @team, assignment: @assignment).run
      true
    else
      false
    end
  end

end
