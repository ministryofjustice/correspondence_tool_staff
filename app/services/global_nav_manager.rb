class GlobalNavManager

  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper

  attr_reader :nav_pages, :request, :user, :settings

  def initialize(user, request, settings)
    @user = user
    @request = request
    @nav_pages = []
    @settings = settings
    add_pages_for_user(user, settings)
  end

  def each
    @nav_pages.each do |nav_page|
      yield(nav_page)
    end
  end

  def current_page
    @current_page ||= @nav_pages.find do |page|
      page.matches_path? request.path
    end
  end

  def current_tab
    @current_tab ||= current_page&.tabs&.find do |tab|
      tab.matches_fullpath? request.fullpath
    end
  end

  def current_cases_finder
    current_tab&.finder || current_page&.finder
  end

  private

  def parse_tabs_list_from_setting(tabs_or_default)
    tabs_or_default.respond_to?(:keys) ? tabs_or_default : {}
  end

  def parse_default_from_setting(tabs_or_default)
    if tabs_or_default.respond_to? :keys
      false
    else
      tabs_or_default.to_s == 'default'
    end
  end

  def get_nav_structure_for_user(user, settings)
    settings.structure.find do |matcher, _structure|
      matcher.to_s == '*' ||
        matcher.to_s.in?(user.teams.pluck :code) ||
        matcher.to_s.in?(user.roles)
    end .last
  end

  def add_pages_for_user(user, settings)
    structure = get_nav_structure_for_user(user, settings)
    @nav_pages = structure.map do |page_name, tabs_or_default|
      tabs_structure = parse_tabs_list_from_setting(tabs_or_default)
      default_page = parse_default_from_setting(tabs_or_default)
      page = Page.new(page_name, user, tabs_structure.keys, settings)

      if default_page
        @default = page
      else
        @default ||= tabs_structure.find { |_,d| d.to_s == 'default' }
      end

      page
    end
  end
end
