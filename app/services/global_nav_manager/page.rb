class GlobalNavManager
  class Page

    attr_reader :name, :text, :urls, :user

    def initialize(name, text, urls, tab_settings, user)
      @name = name
      @text = text
      @urls = urls.is_a?(Array) ? urls : [urls]
      @tab_settings = tab_settings || {}
      @user = user
    end

    def url
      @urls.first
    end

    def tabs
      @tabs ||= @tab_settings.map do |name, params|
        Tab.new(name, url, finder, params)
      end
    end

    def finder
      @finder ||= CaseFinderService.new(user, name)
    end
  end
end
