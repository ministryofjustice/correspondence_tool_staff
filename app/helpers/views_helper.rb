module ViewsHelper
  def get_offender_sar_heading(offender_sar_type)
    if offender_sar_type == "accepted"
      content_tag(:span, t("new.offender_sar.case_type.accepted"), class: "page-heading--secondary") + " #{offender_sar_type}"
    else
      content_tag(:span, t("new.offender_sar.case_type.rejected"), class: "page-heading--secondary") + " #{offender_sar_type}"
    end
  end
end
