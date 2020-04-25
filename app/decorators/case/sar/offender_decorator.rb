class Case::SAR::OffenderDecorator < Case::BaseDecorator

  def sar_response_address
    object.send_by_email? ? object.email : object.postal_address
  end

  def subject_type_display
    object.subject_type.humanize.tr(' ', '-')
  end

  def third_party_display
    object.third_party == true ? 'Yes' : 'No'
  end

  def get_step_partial
    step_name = current_step.split("/").first.tr('-', '_')
    "#{step_name}_step"
  end

  def back_link(mode, previous_step)
    if mode == :edit
      url = h.case_path(id)
    else
      url = "#{h.step_case_sar_offender_index_path}/#{previous_step}"
    end
    h.link_to "Back", url, class: 'govuk-back-link'
  end
end
