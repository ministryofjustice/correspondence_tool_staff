class Case::SAR::OffenderComplaintDecorator < Case::SAR::OffenderBaseDecorator

  include OffenderSARComplaintCaseForm

  def case_route_path
    h.step_case_sar_offender_complaint_index_path
  end

  def complaint_type
    h.t "helpers.label.offender_sar_complaint.complaint_type.#{object.complaint_type}"
  end

end
