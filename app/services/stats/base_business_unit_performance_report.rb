module Stats
  class BaseBusinessUnitPerformanceReport < BaseReport

    R003_SPECIFIC_COLUMNS = {
      business_group:                  'Business group',
      directorate:                     'Directorate',
      business_unit:                   'Business unit',
      business_unit_id:                'Business unit ID',
      new_business_unit_id:       'New business unit ID',
      responsible:                     'Responsible',
      deactivated:                     'Deactivated',
      moved:                           'Moved to',
    }.freeze

    R003_BU_PERFORMANCE_COLUMNS = {
      bu_performance:             'Performance %',
      bu_total:                   'Total received',
      bu_responded_in_time:       'Responded - in time',
      bu_responded_late:          'Responded - late',
      bu_open_in_time:            'Open - in time',
      bu_open_late:               'Open - late',
    }.freeze

    R003_SPECIFIC_SUPERHEADINGS = {
      business_group:                  '',
      directorate:                     '',
      business_unit:                   '',
      business_unit_id:                '',
      new_business_unit_id:       '',
      responsible:                     '',
      deactivated:                     '',
      moved:                           '',
    }.freeze

    R003_BU_PERFORMANCE_SUPERHEADINGS = {
      bu_performance:             'Business unit',
      bu_total:                   'Business unit',
      bu_responded_in_time:       'Business unit',
      bu_responded_late:          'Business unit',
      bu_open_in_time:            'Business unit',
      bu_open_late:               'Business unit',
    }.freeze

    class << self
      def report_format
        BaseReport::XLSX
      end
    end

    def initialize(**options)
      super(**options)

      @generate_bu_columns = options[:generate_bu_columns]
      column_headings = if @generate_bu_columns
                          R003_SPECIFIC_COLUMNS.merge(CaseAnalyser::COMMON_COLUMNS).merge(R003_BU_PERFORMANCE_COLUMNS)
                        else
                          R003_SPECIFIC_COLUMNS.merge(CaseAnalyser::COMMON_COLUMNS)
                        end

      @stats = StatsCollector.new(Team.hierarchy.map(&:id) + [:total], column_headings)
      @superheadings = superheadings
      @stats.add_callback(:before_finalise, -> { Calculations.roll_up_stats_callback(@stats) })
      @stats.add_callback(:before_finalise, -> { Calculations.populate_team_details_callback(@stats) })
      @stats.add_callback(:before_finalise, -> { Calculations::Callbacks.calculate_overall_columns(@stats) })
      @stats.add_callback(:before_finalise, -> { Calculations::Callbacks.calculate_total_columns(@stats) })
      @stats.add_callback(:before_finalise, -> { Calculations::Callbacks.calculate_percentages(@stats) })
    end

    def superheadings
      headings = if @generate_bu_columns
                   (R003_SPECIFIC_SUPERHEADINGS.merge(CaseAnalyser::COMMON_SUPERHEADINGS).merge(R003_BU_PERFORMANCE_SUPERHEADINGS)).values
                 else
                   (R003_SPECIFIC_SUPERHEADINGS.merge(CaseAnalyser::COMMON_SUPERHEADINGS)).values
                 end

      [
        ["#{self.class.title} - #{reporting_period}"], headings
      ]
    end

    def case_scope
      raise '#case_scope method must be defined in derived class'
    end

    def run(*)
      CaseSelector.new(case_scope)
        .cases_received_in_period(@period_start, @period_end)
        .reject { |kase| kase.unassigned? }.each do |kase|
        analyse_case(kase)
      end
      @stats.finalise
    end

    INDEXES_FOR_PERCENTAGE_COLUMNS = [8, 14, 20].freeze

    # This method needs to return a grid of 'cells' with value and rag_rating properties
    def to_csv
      csv = @stats.to_csv(row_names_as_first_column: false, superheadings: superheadings)
      csv.map.with_index do |row, row_index|
        row.map.with_index do |item, item_index|
          # data rows start after 2 superheadings + 1 heading
          if row_index <= superheadings.size
            header_cell row_index, item
          # item at index+1 is the case count - don't mark 0/0 as Red RAG rating
          # These are the positions of the 3 items which need a RAG rating
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
      analyser = CaseAnalyser.new(kase)
      analyser.run
      column_key = analyser.result
      @stats.record_stats(kase.responding_team.id, column_key)

      if @generate_bu_columns
        business_unit_column_key = "bu_#{analyser.bu_result}".to_sym
        @stats.record_stats(kase.responding_team.id, business_unit_column_key)
      end
    end

    def add_trigger_state(kase, timeliness)
      status = kase.flagged? ? 'trigger_' + timeliness : 'non_trigger_' + timeliness
      status.to_sym
    end

    def analyse_closed_case(kase)
      kase.responded_in_time? ? 'responded_in_time' : 'responded_late'
    end

    def analyse_open_case(kase)
      kase.already_late? ? 'open_late' : 'open_in_time'
    end
  end
end
