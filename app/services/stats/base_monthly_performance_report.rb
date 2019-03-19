module Stats
  class BaseMonthlyPerformanceReport < BaseReport

    R005_SPECIFIC_COLUMNS = {
        month:    'Month'
    }

    R005_SPECIFIC_SUPERHEADINGS = {
        month:     ''
    }

    class << self
      def xlsx?
        true
      end
    end

    def initialize(period_start = nil, period_end = nil)
      super
      @stats = StatsCollector.new(array_of_month_numbers + [:total], R005_SPECIFIC_COLUMNS.merge(CaseAnalyser::COMMON_COLUMNS))
      @superheadings = superheadings

      @stats.add_callback(:before_finalise, -> { populate_month_names_callback(@stats) })
      @stats.add_callback(:before_finalise, -> { Calculations::Callbacks.calculate_overall_columns(@stats) })
      @stats.add_callback(:before_finalise, -> { Calculations::Callbacks.calculate_total_columns(@stats) })
      @stats.add_callback(:before_finalise, -> { Calculations::Callbacks.calculate_percentages(@stats) })
    end

    def self.title
      raise '#title method should be defined in sub-class of BaseMonthlyPerformanceReport'
    end

    def self.description
      raise '#description should be defined in sub-class of BaseMonthlyPerformanceReport'
    end

    def run
      CaseSelector.new(case_scope)
        .cases_received_in_period(@period_start, @period_end)
        .includes(:responded_transitions, :approver_assignments, :assign_responder_transitions)
        .reject { |k| k.unassigned? }
        .each { |kase| analyse_case(kase) }
      @stats.finalise
    end

    def to_csv
      csv = @stats.to_csv(row_names_as_first_column: false, superheadings: superheadings)

      csv.map.with_index do |row, row_index|
        row.map.with_index do |item, item_index|
          if row_index <= superheadings.size
            OpenStruct.new value: item
            # item at index+1 is the case count - don't mark 0/0 as Red RAG rating
            # These are the positions of the items which need a RAG rating
          elsif [1, 7, 13].include?(item_index) && row[item_index+1] != 0
            OpenStruct.new value: item, rag_rating: rag_rating(item)
          else
            OpenStruct.new value: item
          end
        end
      end
    end

    private

    def superheadings
      [
          ["#{self.class.title} - #{reporting_period}"],
          R005_SPECIFIC_SUPERHEADINGS.merge(CaseAnalyser::COMMON_SUPERHEADINGS).values
      ]
    end

    def analyse_case(kase)
      analyser = CaseAnalyser.new(kase)
      analyser.run
      column_key = analyser.result
      month = kase.received_date.month
      @stats.record_stats(month, column_key)
      @stats.record_stats(:total, column_key)
    end

    def array_of_month_numbers
      (@period_start.month..@period_end.month).to_a
    end

    def populate_month_names_callback(stats)
      stats.stats.each do |month_no, result_set|
        if month_no == :total
          result_set[:month] = 'Total'
        else
          result_set[:month] = Date::MONTHNAMES[month_no]
        end
      end
    end

  end
end
