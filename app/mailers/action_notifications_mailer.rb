class ActionNotificationsMailer < GovukNotifyRails::Mailer

  def new_assignment(assignment, recipient)
    RavenContextProvider.set_context
    @assignment = assignment
    kase = @assignment.case

    set_template(Settings.new_assignment_notify_template)
    set_personalisation(
        email_subject:      format_subject(kase),
        team_name:          @assignment.team.name,
        case_current_state: I18n.t("state.#{kase.current_state}").downcase,
        case_number:        kase.number,
        case_abbr:          kase.category.abbreviation,
        case_name:          kase.name,
        case_received_date: kase.received_date.strftime(Settings.default_date_format),
        case_subject:       kase.subject,
        case_link: edit_case_assignment_url(@assignment.case_id, @assignment.id)
    )

    mail(to: recipient)
  end

  def ready_for_approver_review(assignment)
    RavenContextProvider.set_context

    kase = assignment.case
    recipient = assignment.user

    set_template(Settings.ready_for_approver_review_notify_template)

    set_personalisation(
        email_subject:          format_subject(kase),
        approver_full_name:     recipient.full_name,
        case_number:            kase.number,
        case_subject:           kase.subject,
        case_type:              kase.category.abbreviation,
        case_name:              kase.name,
        case_received_date:     kase.received_date.strftime(Settings.default_date_format),
        case_external_deadline: kase.external_deadline.strftime(Settings.default_date_format),
        case_link: case_url(kase.id)
    )

    mail(to: recipient.email)
  end

  def case_ready_to_send(kase)
    RavenContextProvider.set_context

    recipient = kase.assignment.last.user

    set_template(Settings.case_ready_to_send_notify_template)

    set_personalisation(
        email_subject:          format_subject(kase),
        approver_full_name:     recipient.full_name,
        case_number:            kase.number,
        case_subject:           kase.subject,
        case_type:              kase.category.abbreviation,
        case_name:              kase.name,
        case_received_date:     kase.received_date.strftime(Settings.default_date_format),
        case_external_deadline: kase.external_deadline.strftime(Settings.default_date_format),
        case_link: case_url(kase.id)
    )

    mail(to: recipient.email)
  end


  private

  def format_subject(kase)
    translation_key = "state.#{kase.current_state}"
    "#{kase.number} - #{kase.category.abbreviation} - #{kase.subject} - #{I18n.t(translation_key)}"
  end

end
