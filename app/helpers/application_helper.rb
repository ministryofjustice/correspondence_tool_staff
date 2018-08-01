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
end
