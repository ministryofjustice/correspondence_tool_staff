module Stats
  class StatsCollector

    attr_reader :stats

    def initialize(categories, subcategories)
      @stats = {}
      categories.each do |cat|
        @stats[cat] = {}
        subcategories.each do |subcat|
          @stats[cat][subcat] = 0
        end
      end
    end

    def record_stats(cat, subcat, count = 1)
      raise ArgumentError.new("No such category: '#{cat}'") unless @stats.key?(cat)
      raise ArgumentError.new("No such sub-category: '#{subcat}'") unless @stats[cat].key?(subcat)
      @stats[cat][subcat] += count
    end

    def categories
      @stats.keys.sort
    end

    def subcategories
      @stats[@stats.keys.first].keys.sort
    end

    def value(cat, subcat)
      @stats[cat][subcat]
    end

  end
end
