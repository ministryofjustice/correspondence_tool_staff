module ViewsHelper
  def get_headings(kase, correspondence_type)
    if kase.current_state == "rejected" && correspondence_type.abbreviation == "OFFENDER_SAR"
      content_tag(:sgit pan t("cases.new.offender_sar.rejected"), class: "page-heading--secondary")
    else
      t4c(kase, "", "sub_heading", case_type: kase.pretty_type)
    end
  end
end
