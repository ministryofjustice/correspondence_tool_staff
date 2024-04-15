module ViewsHelper
  def get_sub_heading(kase, key_path = "")
    if kase.offender_sar? && kase.rejected?
      t4c(kase, key_path, "rejected")
    else
      t4c(kase, key_path, "sub_heading", case_type: kase.decorate.pretty_type)
    end
  end
end
