module CasesHelper

  def accepted_case_attachment_types
    Settings.case_uploads_accepted_types.join ','
  end

  def attachment_filename(url)
    URI.decode(
      File.basename(
        URI.parse(url).path
      )
    )
  rescue
    url
  end

  def action_button_for(event)
    case event
    when :assign_responder
      link_to I18n.t('common.case.assign'),
          new_case_assignment_path(@case),
          class: 'button', method: :patch
    when :accept_responder_assignment, :reject_responder_assignment
      link_to I18n.t('common.case.accept_or_reject'),
          edit_case_assignment_path(@case, @case.assignments.last),
          class: 'button'
    when :close
      link_to I18n.t('common.case.close'),
          close_case_path(@case),
          class: 'button', method: :patch
    end
  end
end
