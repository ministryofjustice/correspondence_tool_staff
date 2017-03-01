module CasesHelper

  def accepted_case_attachment_types
    Settings.case_uploads_accepted_types.join ','
  end

  def action_button_for(event)
    case event
    when :assign_responder
      link_to I18n.t('common.case.assign'),
          new_case_assignment_path(@case),
          class: 'button'
    when :add_responses
      link_to t('common.case.upload_response'),
          new_response_upload_case_path(@case),
          class: 'button'
    when :respond
      link_to t('common.case.respond'),
          respond_case_path(@case),
          class: 'button'
    when :close
      link_to I18n.t('common.case.close'),
          close_case_path(@case),
          class: 'button', method: :patch
    end
  end

  def case_detail_link(kase)
    if kase.current_state == "awaiting_responder" && @user.drafter?
      link_to kase.number,
              edit_case_assignment_path(kase, kase.drafter_assignment)
    else
      link_to kase.number, case_path(kase.id)
    end

  end
end
