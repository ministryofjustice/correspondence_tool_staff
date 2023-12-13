module ViewsHelper
  def get_heading(kase)
    if kase.offender_sar_type == "accepted"
      content_tag(:span, t("cases.new.offender_sar.accepted"), class: "page-heading--secondary")
    else
      content_tag(:span, t("cases.new.offender_sar.rejected"), class: "page-heading--secondary")
    end
  end
end
