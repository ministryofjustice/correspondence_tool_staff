class MailDeliveryObserver
  def self.delivered_email(message)
    return if message.delivery_handler != "ActionNotificationsMailer"

    data_request_email_id = message.header["dreid"]&.value
    return if data_request_email_id.nil?

    data_request_email = DataRequestEmail.find(data_request_email_id)
    data_request_email.update!(notify_id: message.govuk_notify_response.id)
  end
end
