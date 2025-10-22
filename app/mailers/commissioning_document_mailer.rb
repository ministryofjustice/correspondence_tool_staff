class CommissioningDocumentMailer < GovukNotifyRails::Mailer
  attr_reader :data_request_email

  before_action :setup
  after_deliver :set_notify_id

  def commissioning_email(commissioning_document, kase_number, recipient)
    set_template(Settings.commissioning_notify_template)

    set_personalisation(
      CommissioningEmailPersonalisation.new(commissioning_document, kase_number, recipient).personalise,
    )

    @data_request_email = DataRequestEmail.find_or_create_by!(
      email_address: recipient,
      data_request_area: commissioning_document.data_request_area,
    )

    mail(to: recipient)
  end

  def chase_email(kase, commissioning_document, recipient, chase_number)
    set_template(Settings.commissioning_chase_template)

    file = StringIO.new(commissioning_document.document)

    set_personalisation(
      email_subject: email_subject(kase, chase_number),
      email_address: recipient,
      deadline: commissioning_document.deadline,
      deadline_days: commissioning_document.deadline_days,
      link_to_file: Notifications.prepare_upload(file, confirm_email_before_download: true, retention_period: '2 weeks'),
    )

    @data_request_email = DataRequestEmail.find_or_create_by!(
      email_address: recipient,
      data_request_area: commissioning_document.data_request_area,
      email_type: "chase",
      chase_number:,
    )

    mail(to: recipient)
  end

  def chase_escalation_email(kase, commissioning_document, recipient, chase_number)
    set_template(Settings.commissioning_chase_escalation_template)

    file = StringIO.new(commissioning_document.document)

    set_personalisation(
      email_subject: email_subject(kase, chase_number),
      email_address: recipient,
      deadline: commissioning_document.deadline,
      deadline_days: commissioning_document.deadline_days,
      link_to_file: Notifications.prepare_upload(file, confirm_email_before_download: true),
    )

    @data_request_email = DataRequestEmail.find_or_create_by!(
      email_address: recipient,
      data_request_area: commissioning_document.data_request_area,
      email_type: "chase_escalation",
      chase_number:,
    )

    mail(to: recipient)
  end

  def chase_overdue_email(kase, commissioning_document, recipient, chase_number)
    set_template(Settings.commissioning_chase_overdue_template)

    file = StringIO.new(commissioning_document.document)

    set_personalisation(
      email_subject: email_subject(kase, chase_number),
      email_address: recipient,
      deadline: commissioning_document.deadline,
      external_deadline: kase.external_deadline.strftime("%d/%m/%Y"),
      link_to_file: Notifications.prepare_upload(file, confirm_email_before_download: true),
    )

    @data_request_email = DataRequestEmail.find_or_create_by!(
      email_address: recipient,
      data_request_area: commissioning_document.data_request_area,
      email_type: "chase_overdue",
      chase_number:,
    )

    mail(to: recipient)
  end

private

  def setup
    SentryContextProvider.set_context
    set_email_reply_to(Settings.commissioning_notify_reply_to)
  end

  def email_subject(kase, chase_number)
    "Subject Access Request - #{kase.number} - #{kase.subject_full_name} - Chase #{chase_number}"
  end

  def set_notify_id
    return if message.govuk_notify_response.nil?
    return if data_request_email.nil?

    data_request_email.update!(notify_id: message.govuk_notify_response.id)
  end
end
