module ViewsHelper
  def get_offender_sar_heading(offender_sar_type, kase)
    if offender_sar_type == "accepted"
      content_tag(:span, t4c(kase, "", "case_type.accepted", case_type: kase.pretty_type), class: "page-heading--secondary")
    else
      content_tag(:span, t4c(kase, "", "case_type.rejected", case_type: kase.pretty_type), class: "page-heading--secondary")
    end
  end
end
