module ApplicationHelper
  def active_link_class(url)
    #home page
    if current_page?(url)
      'active'
    elsif request.fullpath.start_with?(url)
      'active'
    else
      ''
    end
  end

  def show_disclosure_radios_for_ovt?
    @case.is_a?(Case::OverturnedICO::FOI) || @case.is_a?(Case::OverturnedICO::SAR)
  end
end
