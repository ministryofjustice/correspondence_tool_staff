module PublishesSystemLogEmail
private

  def publish_email_sent_event
    PublishSystemLogEventJob.perform_later(
      Events::EmailSent,
      data: email_event_payload,
    )
  end

  def email_event_payload
    {
      mailer: self.class.name,
      mailer_action: action_name,
      recipient: Array(message.to).join(", "),
      subject: message.subject.presence || notify_personalisation&.[](:email_subject),
      template_id: notify_template,
      notify_id: notify_response_id,
      sent_at: Time.current.iso8601,
    }.merge(email_event_context).compact
  end

  def email_event_context
    {}
  end

  def notify_personalisation
    return unless message.respond_to?(:govuk_notify_personalisation)

    message.govuk_notify_personalisation
  end

  def notify_template
    return unless message.respond_to?(:govuk_notify_template)

    message.govuk_notify_template
  end

  def notify_response_id
    return unless message.respond_to?(:govuk_notify_response)

    message.govuk_notify_response&.id
  end
end
