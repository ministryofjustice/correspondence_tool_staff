module Stats
  class BaseRetentionReport < BaseReport
    class << self
      def title
        "Retention report"
      end

      def description
        "Shows cases whose last action was between the selected dates"
      end

      def report_format
        BaseReport::CSV
      end

      def persist_results?
        false
      end
    end

    def report_type
      raise "#description should be defined in sub-class of BaseRetentionReport"
    end

    def case_scope
      raise "#case_scope should be defined in sub-class of BaseRetentionReport"
    end

    def process(kase)
      raise "#process should be defined in sub-class of BaseRetentionReport"
    end

    def results
      @result_set
    end

    def set_results(data)
      @result_set = data
    end

    def run(*)
      case_scope.each { |kase| @result_set << process(kase) }
    end

    def to_csv
      @result_set.map do |row|
        row.map { |item| OpenStruct.new(value: item) }
      end
    end
  end
end
