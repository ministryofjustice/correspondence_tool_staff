module ViewsHelper
  def get_headings(kase)
    if current_state == "rejected" && type.abbreviation == "OFFENDER_SAR"
      content_tag(:span, t("cases.new.offender_sar.rejected"), class: "page-heading--secondary")
    else
      t4c(kase, "", "sub_heading", case_type: kase.pretty_type)
    end
  end
end
