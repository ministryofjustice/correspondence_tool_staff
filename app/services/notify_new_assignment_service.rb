class NotifyNewAssignmentService
  def initialize(team:, assignment:)
    @team = team
    @assignment = assignment
  end

  def run
    if @team.email.blank?
      @team.responders.each do |responder|
        ActionNotificationsMailer
          .new_assignment(@assignment, responder.email)
          .deliver_later
      end
    else
      ActionNotificationsMailer.new_assignment(@assignment, @team.email).deliver_later
    end
  end
end
