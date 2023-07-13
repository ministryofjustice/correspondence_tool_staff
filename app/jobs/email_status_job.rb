class EmailStatusJob < ApplicationJob
  queue_as :email_status

  def perform(email_id)
    SentryContextProvider.set_context
    email = DataRequestEmail.find email_id
    email.update_status!
  end
end
