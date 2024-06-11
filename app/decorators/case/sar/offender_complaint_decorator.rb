class Case::SAR::OffenderComplaintDecorator < Case::SAR::OffenderBaseDecorator
  include OffenderSARComplaintCaseForm

  def pretty_type
    if object.complaint_type.present?
      "Complaint - #{complaint_type}"
    else
      "Offender SAR Complaint"
    end
  end

  def case_route_path
    h.step_case_sar_offender_complaint_index_path
  end

  def complaint_type
    h.t "helpers.label.offender_sar_complaint.complaint_type.#{object.complaint_type}"
  end

  def highlight_flag
    object.normal? ? "" : "#{object.priority.humanize} priority"
  end
end
