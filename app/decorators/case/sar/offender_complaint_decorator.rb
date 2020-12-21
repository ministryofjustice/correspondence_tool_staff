class Case::SAR::OffenderComplaintDecorator < Case::SAR::OffenderBaseDecorator

  include OffenderSARComplaintCaseForm

  def pretty_type
    "Complaint - #{Case::SAR::OffenderComplaint.complaint_types[object.complaint_type]}"
  end

  def case_route_path
    h.step_case_sar_offender_complaint_index_path
  end

end
