module Stats
  class BaseAppealsPerformanceReport < BaseReport

    R002_SPECIFIC_COLUMNS = {
        business_group:                  'Business group',
        directorate:                     'Directorate',
        business_unit:                   'Business unit',
        responsible:                     'Responsible'
    }.freeze

    R002_SPECIFIC_SUPERHEADINGS = {
        business_group:                  '',
        directorate:                     '',
        business_unit:                   '',
        responsible:                     ''
    }.freeze

    class << self
      def report_format
        BaseReport::XLSX
      end
    end

    def initialize(**options)
      super(**options)

      @stats = StatsCollector.new(Team.hierarchy.map(&:id) + [:total], column_headings)
      @superheadings = superheadings
      @stats.add_callback(:before_finalise, -> { Calculations.roll_up_stats_callback(@stats) })
      @stats.add_callback(:before_finalise, -> { Calculations.populate_team_details_callback(@stats) })
      @stats.add_callback(:before_finalise, -> { AppealCalculations::Callbacks.calculate_total_columns(@stats, appeal_types) })
      @stats.add_callback(:before_finalise, -> { AppealCalculations::Callbacks.calculate_percentages(@stats, appeal_types) })
    end

    def run(*)
      Case::Base.find(case_ids).reject { |k| k.unassigned? }.each { |kase| analyse_case(kase) }
      @stats.finalise
    end

    INDEXES_FOR_PERCENTAGE_COLUMNS = [4, 10].freeze

    def to_csv
      csv = @stats.to_csv(row_names_as_first_column: false, superheadings: superheadings)

      csv.map.with_index do |row, row_index|
        row.map.with_index do |item, item_index|
          # data rows start at index 3 as there are 2 superheadings + 1 heading
          if row_index <= superheadings.size
            header_cell row_index, item
            # item at index+1 is the case count - don't mark 0/0 as Red RAG rating
            # These are the positions of the items which need a RAG rating
          elsif INDEXES_FOR_PERCENTAGE_COLUMNS.include?(item_index) && row[item_index+1] != 0
            OpenStruct.new value: item, rag_rating: rag_rating(item)
          else
            OpenStruct.new value: item
          end
        end
      end
    end

    private

    def analyse_case(kase)
      column_key = analyse_timeliness(kase)
      @stats.record_stats(kase.responding_team.id, column_key)
    end

    def analyse_timeliness(kase)
      AppealAnalyser.new(kase).result
    end

    def analyse_closed_case(kase)
      kase.responded_in_time? ? 'responded_in_time' : 'responded_late'
    end

    def analyse_open_case(kase)
      kase.already_late? ? 'open_late' : 'open_in_time'
    end
  end
end
