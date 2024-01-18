module ViewsHelper
  def get_headings(kase, correspondence_type)
    if kase.current_state == "rejected" && correspondence_type.abbreviation == CorrespondenceType.offender_sar.abbreviation
      t4c(kase, "", t("rejected"), case_type: kase.pretty_type)
    else
      t4c(kase, "", "sub_heading", case_type: kase.pretty_type)
    end
  end
end
