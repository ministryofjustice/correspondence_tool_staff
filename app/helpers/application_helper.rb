module ApplicationHelper
  def active_link_class(url)
    # home page
    if current_page?(url)
      "active"
    elsif request.fullpath.start_with?(url)
      "active"
    else
      ""
    end
  end

  def show_disclosure_radios_for_ovt?(kase)
    kase.is_a?(Case::OverturnedICO::FOI) || kase.is_a?(Case::OverturnedICO::SAR)
  end

  def render_content(&block)
    content_tag(:span, capture(&block), class: "content-wrapper")
  end
end
