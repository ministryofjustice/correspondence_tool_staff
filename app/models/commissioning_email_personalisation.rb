class CommissioningEmailPersonalisation
  attr_reader :commissioning_document, :kase_number, :recipient

  def initialize(commissioning_document, kase_number, recipient)
    @commissioning_document = commissioning_document
    @kase_number = kase_number
    @recipient = recipient
  end

  def personalise
    {
      email_subject: subject,
      email_address: recipient,
      deadline_text:,
      link_to_file:,
    }
  end

private

  def subject
    subject_name = commissioning_document.data_request_area.offender_sar_case.subject_full_name
    "Subject Access Request - #{kase_number} - #{commissioning_document.decorate.request_document} - #{subject_name}"
  end

  def deadline_text
    return "" if commissioning_document.deadline.blank?

    I18n.t("mailer.commissioning_email.deadline", date: commissioning_document.deadline)
  end

  def link_to_file
    file = StringIO.new(commissioning_document.document)
    Notifications.prepare_upload(file, confirm_email_before_download: true, retention_period: "4 weeks")
  end
end
