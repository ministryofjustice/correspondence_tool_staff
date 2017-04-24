module CasesHelper

  def accepted_case_attachment_types
    Settings.case_uploads_accepted_types.join ','
  end

  def action_button_for(event)
    case event
    when :assign_responder
      link_to I18n.t('common.case.assign'),
              new_case_assignment_path(@case),
              id: 'action--assign-to-responder',
              class: 'button'
    when :add_responses
      link_to t('common.case.upload_response'),
              new_response_upload_case_path(@case),
              id: 'action--upload-response',
              class: 'button'
    when :respond
      link_to t('common.case.respond'),
              respond_case_path(@case),
              id: 'action--mark-response-as-sent',
              class: 'button'
    when :close
      link_to I18n.t('common.case.close'),
              close_case_path(@case),
              id: 'action--close-case',
              class: 'button', method: :get
    end
  end

  def attachment_download_link(kase, attachment)
    link_to t('common.case.download_link_html', filename: attachment.filename),
            download_case_case_attachment_path(kase, attachment)

  end

  def attachment_preview_link(attachment)
    if attachment.preview_key != nil
      "#{link_to "View", case_case_attachment_path(attachment.case, attachment),  target: '_blank'}".html_safe
    else
      ''
    end
  end

  def attachment_remove_link(kase, attachment)
    link_to t('common.case.remove_link_html', filename: attachment.filename),
            case_case_attachment_path(kase, attachment),
            method: :delete,
            remote: true,
            data: {
              confirm: "Are you sure you want to remove #{attachment.filename}?"
            }
  end

  def exemptions_checkbox_selector(exemption, kase)
    if kase.exemptions.map(&:id).include?(exemption.id)
      'selected'
    else
      ''
    end
  end

end
