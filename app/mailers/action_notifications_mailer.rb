class ActionNotificationsMailer < GovukNotifyRails::Mailer
  def new_assignment(assignment, recipient)
    SentryContextProvider.set_context
    @assignment = assignment
    kase = @assignment.case
    return unless kase

    set_template(Settings.new_assignment_notify_template)
    set_personalisation(
      email_subject: format_subject(kase),
      team_name: @assignment.team.name,
      case_current_state: I18n.t("state.#{kase.current_state}").downcase,
      case_number: kase.number,
      case_abbr: kase.decorate.pretty_type,
      case_received_date: kase.received_date.strftime(Settings.default_date_format),
      case_subject: kase.subject,
      case_link: edit_case_assignment_url(@assignment.case_id, @assignment.id),
    )

    mail(to: recipient)
  end

  def ready_for_press_or_private_review(assignment)
    SentryContextProvider.set_context

    kase = assignment.case
    recipient = assignment.user

    set_template(Settings.ready_for_press_or_private_review_notify_template)

    set_personalisation(
      email_subject: format_subject(kase),
      approver_full_name: recipient.full_name,
      case_number: kase.number,
      case_type: kase.decorate.pretty_type,
      case_subject: kase.subject,
      case_received_date: kase.received_date.strftime(Settings.default_date_format),
      case_external_deadline: kase.external_deadline.strftime(Settings.default_date_format),
      case_link: case_url(kase.id),
    )

    mail(to: recipient.email)
  end

  def notify_information_officers(kase, type)
    SentryContextProvider.set_context

    recipient = kase.assignments.responding.accepted.first&.user
    return unless recipient

    find_template(type)

    set_personalisation(
      email_subject: format_subject_type(kase, type),
      responder_full_name: recipient.full_name,
      case_current_state: I18n.t("state.#{kase.current_state}").downcase,
      case_number: kase.number,
      case_subject: kase.subject,
      case_abbr: kase.decorate.pretty_type,
      case_received_date: kase.received_date.strftime(Settings.default_date_format),
      case_external_deadline: kase.external_deadline.strftime(Settings.default_date_format),
      case_link: case_url(kase.id),
      case_draft_deadline: kase.internal_deadline.strftime(Settings.default_date_format),
    )

    mail(to: recipient.email)
  end

  def notify_team(team, kase, notification_type)
    SentryContextProvider.set_context

    find_template(notification_type)

    set_personalisation(
      email_subject: format_subject_type(kase, notification_type),
      name: team.name,
      case_number: kase.number,
      case_abbr: kase.decorate.pretty_type,
      case_subject: kase.subject,
      case_received_date: kase.received_date.strftime(Settings.default_date_format),
      case_external_deadline: kase.external_deadline.strftime(Settings.default_date_format),
      case_link: case_url(kase.id),
    )

    mail(to: team.email)
  end

  def case_assigned_to_another_user(kase, recipient)
    SentryContextProvider.set_context

    set_template(Settings.assigned_to_another_user_template)

    set_personalisation(
      email_subject: format_subject_type(kase, "Assigned to you"),
      user_name: recipient.full_name,
      case_number: kase.number,
      case_subject: kase.subject,
      case_abbr: kase.decorate.pretty_type,
      case_received_date: kase.received_date.strftime(Settings.default_date_format),
      case_external_deadline: kase.external_deadline.strftime(Settings.default_date_format),
      case_link: case_url(kase.id),
    )

    mail(to: recipient.email)
  end

  def commissioning_email(commissioning_document, recipient)
    SentryContextProvider.set_context

    find_template("Commissioning")

    deadline_text = ""
    if commissioning_document.deadline.present?
      deadline_text = I18n.t("mailer.commissioning_email.deadline", date: commissioning_document.deadline)
    end

    file = StringIO.new(commissioning_document.document)

    set_personalisation(
      email_address: recipient,
      deadline_text:,
      link_to_file: Notifications.prepare_upload(file, confirm_email_before_download: true),
    )

    data_request_email = DataRequestEmail.find_or_create_by!(
      email_address: recipient,
      data_request: commissioning_document.data_request,
    )

    # Sets dreid header with reference to record which can be used to update with Notify ID in MailDeliveryObserver
    mail(to: recipient, dreid: data_request_email.id)
  end

private

  def format_subject(kase)
    translation_key = "state.#{kase.current_state}"
    "#{I18n.t(translation_key)} - #{kase.decorate.pretty_type} - #{kase.number} - #{kase.subject}"
  end

  def format_subject_type(kase, type)
    "#{type} - #{kase.decorate.pretty_type} - #{kase.number} - #{kase.subject}"
  end

  def find_template(type)
    case type
    when "Case closed"
      set_template(Settings.case_closed_notify_template)
    when "Redraft requested"
      set_template(Settings.redraft_requested_notify_template)
    when "Responses have been sent back"
      set_template(Settings.responses_sent_back_notify_template)
    when "Ready to send"
      set_template(Settings.case_ready_to_send_notify_template)
    when "Message received"
      set_template(Settings.message_received_notify_template)
    when "Commissioning"
      set_template(Settings.commissioning_notify_template)
    end
  end
end
