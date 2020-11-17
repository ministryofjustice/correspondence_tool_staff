class Case::SAR::OffenderBaseDecorator < Case::BaseDecorator

  include Steppable
 
  def back_link(mode, previous_step)
  url = if mode == :edit
          h.case_path(id)
        else
          "#{case_route_path}/#{previous_step}"
        end
  h.link_to "Back", url, class: 'govuk-back-link'
  end
 
  def get_step_partial
    step_name = current_step.split("/").first.tr('-', '_')
    "#{step_name}_step"
  end
 
  def subject_type_display
    I18n.t('helpers.label.offender_sar.subject_type.' + object.subject_type)
  end
 
  def third_party_display
    object.third_party ? 'Yes' : 'No'
  end
 
  def time_taken
    calendar_days_taken
  end

  def case_route_path
  raise "Need to be implemented in the sub class"
  end

end
 