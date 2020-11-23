class Case::SAR::OffenderComplaintDecorator < Case::SAR::OffenderDecorator

  include Steppable
  include OffenderSARComplaintCaseForm

  def back_link(mode, previous_step)
   url = if mode == :edit
           h.case_path(id)
         else
           "#{h.step_case_sar_offender_complaint_index_path}/#{previous_step}"
         end
   h.link_to "Back", url, class: 'govuk-back-link'
  end

end
