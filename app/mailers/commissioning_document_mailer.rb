class CommissioningDocumentMailer < GovukNotifyRails::Mailer
  include PublishesSystemLogEmail

  attr_reader :data_request_email

  before_action :setup
  after_deliver :set_notify_id
  after_deliver :publish_email_sent_event

  def commissioning_email(commissioning_document, kase_number, recipient)
    set_template(Settings.commissioning_notify_template)

    set_personalisation(
      CommissioningEmailPersonalisation.new(commissioning_document, kase_number, recipient).personalise,
    )

    @data_request_email = DataRequestEmail.find_or_create_by!(
      email_address: recipient,
      data_request_area: commissioning_document.data_request_area,
    )

    set_email_event_context(
      case_number: kase_number,
      category: "commissioning_document",
      commissioning_document:,
      email_type: @data_request_email.email_type,
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
      link_to_file: Notifications.prepare_upload(file, confirm_email_before_download: true),
    )

    @data_request_email = DataRequestEmail.find_or_create_by!(
      email_address: recipient,
      data_request_area: commissioning_document.data_request_area,
      email_type: "chase",
      chase_number:,
    )

    set_email_event_context(
      case_number: kase.number,
      category: "commissioning_document",
      chase_number:,
      commissioning_document:,
      email_type: @data_request_email.email_type,
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

    set_email_event_context(
      case_number: kase.number,
      category: "commissioning_document",
      chase_number:,
      commissioning_document:,
      email_type: @data_request_email.email_type,
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

    set_email_event_context(
      case_number: kase.number,
      category: "commissioning_document",
      chase_number:,
      commissioning_document:,
      email_type: @data_request_email.email_type,
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

  def email_event_context
    @email_event_context.merge(
      data_request_area_id: data_request_email&.data_request_area_id,
      data_request_email_id: data_request_email&.id,
      status: data_request_email&.status,
      data_request_email_status: data_request_email&.status,
    ).compact
  end

  def set_email_event_context(case_number:, category:, commissioning_document:, email_type:, chase_number: nil)
    @email_event_context = {
      case_id: commissioning_document.data_request_area.case_id,
      case_number:,
      category:,
      commissioning_document_id: commissioning_document.id,
      email_type:,
      recipient_type: "external",
      chase_number:,
    }.compact
  end
end
