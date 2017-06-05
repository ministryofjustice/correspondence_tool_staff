class GlobalNavManager

  class Tab
    include ActionView::Helpers::UrlHelper

    attr_reader :name, :finder, :params

    def initialize(name, base_url, finder, params)
      @name = name
      @base_url = base_url
      @finder = finder.filter_for_params(params)
      @params = params
    end

    def url
      @url ||= URI.parse(@base_url).tap do |url|
        url.query = params.to_h.to_query
      end .to_s
    end

    def matches_url?(match_url)
      return true if url == match_url
      tab_url_parsed = URI.parse(url)
      match_url_parsed = URI.parse(match_url)

      # We don't match hosts yet, will we ever need to?
      if tab_url_parsed.path != match_url_parsed.path
        return false
      else
        tab_params = parse_query(tab_url_parsed.query)
        match_url_params = remove_pagination_params(
          parse_query(match_url_parsed.query)
        )

        tab_params == match_url_params
      end
    end

    private

    PAGINATION_PARAMS = ['page']

    def parse_query(query)
      return if query.nil?
      CGI.parse(query)
    end

    def remove_pagination_params(params)
      return if params.nil?
      params.reject! { |k,_v| PAGINATION_PARAMS.include? k }
    end
  end
end
