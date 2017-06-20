class GlobalNavManager

  class Tab
    include ActionView::Helpers::UrlHelper

    attr_reader :name, :finder, :params

    def initialize(name, path, finder, settings)
      @name = name
      @path = path
      @params = settings.tabs[name].params
      @finder = finder.filter_for_params(@params)
    end

    def url
      if @url.nil?
        url = URI(@path)
        url.query = params.to_h.to_query
        @url = url.to_s
      end
      @url
    end

    def matches_fullpath?(match_fullpath)
      return true if fullpath == match_fullpath
      match_url = URI.parse(match_fullpath)

      if @path != match_url.path
        return false
      else
        match_params = query_to_h(match_url.query)
        @params.to_h.with_indifferent_access ==
          remove_pagination_params(match_params)
      end
      # We don't match hosts yet, will we ever need to?
    end

    private

    PAGINATION_PARAMS = ['page']

    def fullpath
      @fullpath ||= "#{@path}?#{@params.to_h.to_query}"
    end

    def query_to_h(query)
      Rack::Utils.parse_nested_query(query)
    end

    def remove_pagination_params(params)
      return if params.nil?
      params.reject { |k,_v| PAGINATION_PARAMS.include? k }
    end
  end
end
