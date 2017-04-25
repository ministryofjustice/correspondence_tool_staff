module ApplicationHelper
  def active_link_class urls
    #home page
    if urls.any? { |url| current_page?(url)}
      'active'
    else
      ''
    end
  end
end
