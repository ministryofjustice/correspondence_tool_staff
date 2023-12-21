module ViewsHelper
  def get_sar_heading(kase)
    if @case.current_state == "rejected" # rubocop:disable Rails/HelperInstanceVariable
      content_tag(:span, t("cases.new.offender_sar.rejected"), class: "page-heading--secondary")
    else
      t4c(kase, "", "sub_heading", case_type: kase.pretty_type)
    end
  end
end
