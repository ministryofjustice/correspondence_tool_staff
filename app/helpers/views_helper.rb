module ViewsHelper
  def get_offender_sar_heading(offender_sar_type, _kase)
    if offender_sar_type == "accepted"
      content_tag(:span, t("cases.new.offender_sar.sub_heading"), class: "page-heading--secondary")
    else
      content_tag(:span, t("cases.new.offender_sar.rejected"), class: "page-heading--secondary")
    end
  end
end
