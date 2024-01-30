module ViewsHelper
  def get_heading(kase, correspondence_type, key_path = "")
    if kase.current_state == "rejected" && correspondence_type.abbreviation == CorrespondenceType.offender_sar.abbreviation
      t4c(kase, key_path, "offender_sar.rejected", case_type: kase.decorate.pretty_type)
    else
      t4c(kase, key_path, "sub_heading", case_type: kase.decorate.pretty_type)
    end
  end
end
