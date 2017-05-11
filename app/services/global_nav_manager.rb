class GlobalNavManager

  include Rails.application.routes.url_helpers

  class GlobalNavManagerEntry

    attr_reader :text, :urls

    def initialize(text, urls)
      @text = text
      @urls = urls.is_a?(Array) ? urls : [urls]
    end

    def url
      @urls.first
    end

  end

  attr_reader :nav_entries

  def initialize(user)
    @user = user
    @nav_entries = []
    add_views_for_user
  end

  def each
    @nav_entries.each do |nav_entry|
      yield(nav_entry)
    end
  end

  private

  def add_views_for_user
    return if @user&.team_roles.blank?
    role = @user.team_roles.first.role
    views = Settings.global_navigation.user_views[role]
    views.each do |user_view|
      @nav_entries << entry_for_view(user_view)
    end
  end

  def entry_for_view(view_name)
    GlobalNavManagerEntry.new(I18n.t("nav.#{view_name}"), Settings.global_navigation.paths[view_name])
  end
end
