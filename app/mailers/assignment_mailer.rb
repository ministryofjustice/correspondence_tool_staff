class AssignmentMailer < ApplicationMailer

  def new_assignment(assignment)
    @assignment = assignment
    mail to: @assignment.assignee.email,
         from: 'noreply@digital.justice.gov.uk',
         subject: format_new_assignment_subject
  end

  private

  def format_new_assignment_subject
    kase = @assignment.case
    translation_key = "state.#{kase.current_state}"
    "#{kase.number} - #{kase.category.abbreviation} - #{kase.subject} - #{I18n.t(translation_key)}"
  end

end