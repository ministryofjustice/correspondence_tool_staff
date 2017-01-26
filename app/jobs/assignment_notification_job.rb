class AssignmentNotificationJob < ApplicationJob
  queue_as :mailers

  def perform(*_args)
    # Do something later
  end
end
