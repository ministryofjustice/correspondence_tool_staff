class AssignmentMailer < GovukNotifyRails::Mailer

  def new_assignment(assignment)
    @assignment = assignment
    kase = @assignment.case

    set_template(Settings.new_assignment_notify_template)
    set_personalisation(
        email_subject:      format_new_assignment_subject(kase),
        team_name:          @assignment.team.name,
        case_current_state: I18n.t("state.#{kase.current_state}").downcase,
        case_number:        kase.number,
        case_abbr:          kase.category.abbreviation,
        case_name:          kase.name,
        case_received_date: kase.received_date,
        case_subject:       kase.subject,
        case_link: edit_case_assignment_url(@assignment.case_id, @assignment.id)
    )

    mail(to: @assignment.team.email)
  end

  private

  def format_new_assignment_subject(kase)
    translation_key = "state.#{kase.current_state}"
    "#{kase.number} - #{kase.category.abbreviation} - #{kase.subject} - #{I18n.t(translation_key)}"
  end

end
