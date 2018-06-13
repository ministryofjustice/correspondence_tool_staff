module Stats
  class R005MonthlyPerformanceReport < BaseReport

    R005_SPECIFIC_COLUMNS = {
      month:    'Month'
    }

    R005_SPECIFIC_SUPERHEADINGS = {
      month:     ''
    }

    def initialize(period_start= Time.now.beginning_of_year, period_end=Time.now)
      super
      @period_start = period_start
      @period_end = period_end
      @stats = StatsCollector.new(array_of_month_numbers + [:total], R005_SPECIFIC_COLUMNS.merge(CaseAnalyser::COMMON_COLUMNS))
      @superheadings = superheadings

      @stats.add_callback(:before_finalise, -> { populate_month_names_callback(@stats) })
      @stats.add_callback(:before_finalise, -> { Calculations::Callbacks.calculate_overall_columns(@stats) })
      @stats.add_callback(:before_finalise, -> { Calculations::Callbacks.calculate_total_columns(@stats) })
      @stats.add_callback(:before_finalise, -> { Calculations::Callbacks.calculate_percentages(@stats) })
    end

    def self.title
      'Monthly report'
    end

    def self.description
      'Shows number of cases in each state by month'
    end

    def run
      case_ids = CaseSelector.new(Case::Base.standard_foi).ids_for_cases_received_in_period(@period_start, @period_end)
      case_ids.each { |case_id| analyse_case(case_id) }
      @stats.finalise
    end

    def to_csv
      @stats.to_csv(row_names_as_first_column: false, superheadings: superheadings)
    end

    private

    def superheadings
      [
        ["#{self.class.title} - #{reporting_period}"],
        R005_SPECIFIC_SUPERHEADINGS.merge(CaseAnalyser::COMMON_SUPERHEADINGS).values
      ]
    end

    def analyse_case(case_id)
      kase = Case::Base.find case_id
      unless kase.unassigned?
        analyser = CaseAnalyser.new(kase)
        analyser.run
        column_key = analyser.result
        month = kase.received_date.month
        @stats.record_stats(month, column_key)
        @stats.record_stats(:total, column_key)
      end
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
