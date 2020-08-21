class Case::SAR::OffenderDecorator < Case::BaseDecorator

 include Steppable
 include OffenderSARCaseForm

  def subject_type_display
    I18n.t('helpers.label.offender_sar.subject_type.' + object.subject_type)
  end

  def third_party_display
    object.third_party == true ? 'Yes' : 'No'
  end

  def get_step_partial
    step_name = current_step.split("/").first.tr('-', '_')
    "#{step_name}_step"
  end

  def time_taken
    days = (date_responded - received_date).to_i
    I18n.t('common.case.offender_sar.time_taken_result', count: days)
  end

  def back_link(mode, previous_step)
    url = if mode == :edit
            h.case_path(id)
          else
            "#{h.step_case_sar_offender_index_path}/#{previous_step}"
          end
    h.link_to "Back", url, class: 'govuk-back-link'
  end

end
