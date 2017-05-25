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
      if @tab_settings.empty?
        @urls.first
      else
        tabs.first.url
      end
    end

    def tabs
      @tabs ||= @tab_settings.map do |tab_name, params|
        Tab.new(tab_name, @urls.first, finder, params)
      end
    end

    def finder
      @finder ||= CaseFinderService.new(user, name)
    end
  end
end
