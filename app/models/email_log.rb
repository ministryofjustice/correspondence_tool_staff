# STI subclass of SystemLog for email delivery logging
class EmailLog < SystemLog
  def to
    metadata["to"]
  end

  def from
    metadata["from"]
  end

  def subject
    metadata["subject"]
  end

  def mailer_class
    source
  end

  def mailer_action
    action
  end

  def message_id
    reference_id
  end

  def self.create_from_message(message)
    create!(
      reference_id: message.message_id,
      source: message.delivery_handler&.name,
      action: message.action_name,
      status: "pending",
      metadata: {
        to: Array(message.to).join(", "),
        from: Array(message.from).join(", "),
        subject: message.subject,
      },
    )
  end
end
