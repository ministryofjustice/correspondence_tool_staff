class GlobalNavManager
  class Tab
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
  end
end
