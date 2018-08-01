class NotifyNewAssignmentService

  def initialize(team:, assignment:)
    @team = team
    @assignment = assignment
  end

  def run
    Rails.logger.debug ">>>>>>>>>> running class NotifyNewAssignmentService #{__FILE__}:#{__LINE__} <<<<<<<<<<"
    puts ">>>>>>>>>> running class NotifyNewAssignmentService #{__FILE__}:#{__LINE__} <<<<<<<<<<"
    if @team.email.blank?
      @team.responders.each do |responder|
        puts ">>>>>>>>>> sending to #{responder.email} #{__FILE__}:#{__LINE__} <<<<<<<<<<"
        ActionNotificationsMailer
          .new_assignment(@assignment, responder.email)
          .deliver_later
      end
    else
      Rails.logger.debug ">>>>>>>>>> sending to #{@team.email} #{__FILE__}:#{__LINE__} <<<<<<<<<<"
      puts ">>>>>>>>>> sending to #{@team.email} #{__FILE__}:#{__LINE__} <<<<<<<<<<"
      ActionNotificationsMailer.new_assignment(@assignment, @team.email).deliver_later
    end
  end

end
