class GlobalNavManager

  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper

  attr_reader :nav_pages, :request

  def initialize(user, request)
    @user = user
    @request = request
    @nav_pages = []
    add_pages_for_user
  end

  def each
    @nav_pages.each do |nav_page|
      yield(nav_page)
    end
  end

  def current_page
    @current_page ||= Settings.global_navigation.pages.find do |_name, attrs|
      url_for(attrs.path) == request.path
    end&.tap { |name, _settings| break build_page name }
  end

  def current_tab
    @current_tab ||= current_page&.tabs&.detect do |tab|
      url_for(tab.url) == request.fullpath
    end
  end

  def current_cases_finder
    current_tab&.finder || current_page&.finder
  end

  private

  def add_pages_for_user
    return if @user&.team_roles.blank?
    role = @user.team_roles.first.role
    user_pages = Settings.global_navigation.user_roles[role]
    user_pages.each do |user_page|
      @nav_pages << build_page(user_page)
    end
  end

  def build_page(page_name)
    settings = Settings.global_navigation.pages[page_name]
    Page.new(
      page_name,
      I18n.t("nav.#{page_name}"),
      settings.path,
      settings.tabs,
      @user,
    )
  end
end
