class GlobalNavManager
  class Page

    attr_reader :name, :text, :tabs, :settings, :path

    def initialize(name, user, tab_names, settings, url_params)
      @name = name
      @text = I18n.t("nav.pages.#{name}")
      @user = user
      @path = settings.pages[name].path
      @settings = settings
      @url_params = url_params
      @tabs = build_tabs(tab_names, settings)
    end

    def url
      if @tabs.empty?
        @path
      else
        tabs.first.url
      end
    end

    def finder
      @finder ||= CaseFinderService.new.for_user(@user).for_action(name)
    end

    def matches_path?(match_path)
      @path == match_path
    end

    private

    def build_tabs(tab_names, settings)
      tab_names.map do |tab_name|
        Tab.new(tab_name, @path, finder, settings, @url_params)
      end
    end
  end
end
