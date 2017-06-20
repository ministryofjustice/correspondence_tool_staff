module ApplicationHelper
  def active_link_class(url)
    #home page
    if current_page?(url)
      'active'
    else
      ''
    end
  end
end
