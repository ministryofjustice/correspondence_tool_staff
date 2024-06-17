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
    if high_priority?
      h.content_tag :div, id: "flag", class: "#{object.type_abbreviation.downcase}-highlight-flag" do
        "#{h.content_tag(:span, 'This is a ', class: 'visually-hidden')}#{object.priority.capitalize} priority#{h.content_tag(:span, ' case', class: 'visually-hidden')}"
      end
    else
      " "
    end
  end
end
