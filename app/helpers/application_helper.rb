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
    (@case.is_a?(Case::OverturnedICO::FOI) && FeatureSet.overturned_trigger_fois.enabled?) ||
      (@case.is_a?(Case::OverturnedICO::SAR) && FeatureSet.overturned_trigger_sars.enabled?)
  end
end
