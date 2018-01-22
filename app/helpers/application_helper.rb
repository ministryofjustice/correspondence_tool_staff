module ApplicationHelper
  def active_link_class(url)
    #home page
    if current_page?(url)
      'active'
    else
      ''
    end
  end

  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end
end
