class Case::SAR::OffenderComplaintDecorator < Case::SAR::OffenderBaseDecorator

  include OffenderSARComplaintCaseForm

  def pretty_type
    if object.complaint_type.present?
      "Complaint - #{Case::SAR::OffenderComplaint.complaint_types[object.complaint_type]}"
    else
      "Offender SAR Complaint"
    end
  end

  def case_route_path
    h.step_case_sar_offender_complaint_index_path
  end

end
