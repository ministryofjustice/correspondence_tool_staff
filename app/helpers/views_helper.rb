module ViewsHelper
  def get_offender_sar_heading(offender_sar_type, case)
    if offender_sar_type == "accepted"
      content_tag(:span, t4c(kase, "", "case_type.accepted", case_type: kase.pretty_type), class: "page-heading--secondary")
    else
      content_tag(:span, t(offender_sar.case_type.rejected), class: "page-heading--secondary")
    end
  end
end
