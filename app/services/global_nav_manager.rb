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
    populate_nav_entries
  end

  def each
    @nav_entries.each do |nav_entry|
      yield(nav_entry)
    end
  end

  private

  def populate_nav_entries
    view_cases
    view_closed_cases
  end

  def view_cases
    @nav_entries << GlobalNavManagerEntry.new(I18n.t('nav.cases'), [cases_path, root_path])
  end

  def view_closed_cases
    @nav_entries << GlobalNavManagerEntry.new(I18n.t('nav.closed_cases'), closed_cases_path)
  end
end
