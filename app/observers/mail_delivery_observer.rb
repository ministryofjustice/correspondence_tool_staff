class MailDeliveryObserver
  def self.delivered_email(message)
    data_request_email_id = message.header["dreid"].value
    data_request_email = DataRequestEmail.find(data_request_email_id)
    data_request_email.update!(notify_id: message.govuk_notify_response.id)
  end
end
