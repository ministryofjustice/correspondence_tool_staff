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
      if url == match_url
        return true
      else
        url_parsed = URI.parse(url)
        match_url_parsed = URI.parse(match_url)

        # We don't match hosts yet, will we ever need to?
        if url_parsed.path != match_url_parsed.path
          return false
        elsif url_parsed.query.nil? && match_url_parsed.query.nil?
          return true
        elsif url_parsed.query && match_url_parsed.query.nil?
          return false
        else
          our_params = CGI.parse(url_parsed.query)
          match_params = CGI.parse(match_url_parsed.query)
          pagination_params = ['page']
          match_params.reject! { |k,_v| pagination_params.include? k }
          our_params == match_params
        end
      end
    end
  end
end
