module Stats
  class StatsCollector

    attr_reader :stats

    def initialize
      @stats = Hash.new { |h, k| h[k] = Hash.new { |hh, kk| hh[kk] = 0 } }
    end

    def record_stats(cat, subcat, count = 1)
      @stats[cat][subcat] += count
    end

    def categories
      @stats.keys.sort
    end

    def subcategories_for(cat)
      @stats[cat].keys.sort
    end

    def value(cat, subcat)
      @stats[cat][subcat]
    end

    def all_subcategories
      subcats = []
      @stats.each { |_cat, hash| subcats << hash.keys }
      subcats.flatten.uniq.sort
    end
  end
end
