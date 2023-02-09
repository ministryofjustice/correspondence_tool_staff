class GlobalNavManager
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper

  attr_reader :nav_pages, :request, :user

  def initialize(user, request, pages)
    @user = user
    @request = request
    @nav_pages = pages_for_user(pages)
  end

  def each
    @nav_pages.each do |nav_page|
      yield(nav_page)
    end
  end

  def current_page_or_tab
    @current_page_or_tab ||= page_or_tab_for_request(@request)
  end

  def current_page
    if current_page_or_tab.is_a? Tab
      current_page_or_tab.parent
    else
      current_page_or_tab
    end
  end

  def finder
    CaseFinderService.new(user).for_params(request.params)
  end

  private

  def page_or_tab_for_request(request)
    @nav_pages.each do |page|
      if page.tabs.present?
        page.tabs.each do |tab|
          return tab if tab.matches_path?(request.path)
        end
      else
        return page if page.matches_path?(request.path)
      end
    end
    nil
  end

  def pages_for_user(pages)
    pages.map do |page_name, page_settings|
      Page.new(name: page_name, parent: self, attrs: page_settings)
    end.compact.select(&:visible?)
  end
end
