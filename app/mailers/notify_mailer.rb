class NotifyMailer < GovukNotifyRails::Mailer
  rescue_from Exception, with: :log_errors

  def notify_drafters_of_new_assignments assignment

    @assignment = assignment
    kase = @assignment.case

    set_template('6f4d8e34-96cb-482c-9428-a5c1d5efa519')

    set_personalisation(
        email_subject: format_new_assignment_subject(kase),
        team_name: @assignment.team.name,
        case_current_state: I18n.t("state.#{@assignment.case.current_state}").downcase,
        case_number: @assignment.case.number,
        case_abbr: @assignment.case.category.abbreviation,
        case_name: @assignment.case.name,
        case_received_date: @assignment.case.received_date,
        case_subject: @assignment.case.subject,
        case_link: edit_case_assignment_url(@assignment.case_id, @assignment.id)
    )

    mail(to: @assignment.team.email)
  end

  private

  def format_new_assignment_subject kase
    translation_key = "state.#{kase.current_state}"
    "#{kase.number} - #{kase.category.abbreviation} - #{kase.subject} - #{I18n.t(translation_key)}"
  end

end
