module ViewsHelper
  def get_sub_heading(kase, key_path = "")
    if kase.offender_sar? && kase.rejected?
      t4c(kase, key_path, "rejected")
    else
      t4c(kase, key_path, "sub_heading", case_type: kase.decorate.pretty_type)
    end
  end

  def data_request_status_tag(status)
    case status
    when "Completed"
      "<strong class='govuk-tag'>Completed</strong>".html_safe
    when "In progress"
      "<strong class='govuk-tag govuk-tag--yellow'>In progress</strong>".html_safe
    when "Not started"
      "<strong class='govuk-tag govuk-tag--grey'>Not started</strong>".html_safe
    end
  end
end
