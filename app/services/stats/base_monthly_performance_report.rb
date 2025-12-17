module Stats
  ROWS_PER_FRAGMENT = 100 # Arbitrary value, may require experimentation
  MAXIMUM_LIMIT_FOR_USING_JOB = 500 # Arbitrary value, may require experimentation

  class BaseMonthlyPerformanceReport < BaseReport
    MONTHLY_PERFORMANCE_SPECIFIC_COLUMNS = {
      month: "Month",
    }.freeze

    MONTHLY_PERFORMANCE_SPECIFIC_SUPERHEADINGS = {
      month: "",
    }.freeze

    class << self
      def report_format
        BaseReport::XLSX
      end

      def title
        raise "#title method should be defined in sub-class of BaseMonthlyPerformanceReport"
      end

      def description
        raise "#description should be defined in sub-class of BaseMonthlyPerformanceReport"
      end

      def case_analyzer
        Stats::CaseAnalyser
      end

      def indexes_for_percentage_columns
        [1, 7, 13].freeze
      end

      def report_notes
        ["Performance % =  ((Responded - in time + Open - in time) / Total received) * 100 "]
      end

      def start_position_for_main_body
        2
      end
    end

    def initialize(**options)
      super(**options)
      @stats = StatsCollector.new(array_of_month_numbers + [:total], MONTHLY_PERFORMANCE_SPECIFIC_COLUMNS.merge(self.class.case_analyzer::COMMON_COLUMNS))
      @superheadings = superheadings

      @stats.add_callback(:before_finalise, -> { populate_month_names_callback(@stats) })
      add_report_callbacks
    end

    def add_report_callbacks
      @stats.add_callback(:before_finalise, -> { Calculations::Callbacks.calculate_overall_columns(@stats) })
      @stats.add_callback(:before_finalise, -> { Calculations::Callbacks.calculate_total_columns(@stats) })
      @stats.add_callback(:before_finalise, -> { Calculations::Callbacks.calculate_percentages(@stats) })
    end

    def process(offset, report_job_guid: nil, record_limit: ROWS_PER_FRAGMENT)
      CaseSelector.new(case_scope)
        .cases_received_in_period(@period_start, @period_end)
        .order(:id)
        .limit(record_limit)
        .offset(offset)
        .includes(:responded_transitions, :approver_assignments, :assign_responder_transitions)
        .each { |kase| analyse_case(kase) }

      unless report_job_guid.nil?
        Sidekiq.redis { |r| r.set(report_job_guid, @stats.stats.to_json, ex: 7.days.to_i) }
      end
    end

    def run(*)
      if data_size > MAXIMUM_LIMIT_FOR_USING_JOB
        create_background_jobs
      else
        @background_job = false
        @status = Stats::BaseReport::COMPLETE
        process(0, record_limit: MAXIMUM_LIMIT_FOR_USING_JOB)
        @stats.finalise
      end
    end

    def to_csv
      csv = @stats.to_csv(row_names_as_first_column: false, superheadings:)

      csv.map.with_index do |row, row_index|
        row.map.with_index do |item, item_index|
          if row_index <= superheadings.size
            header_cell row_index, item
            # item at index+1 is the case count - don't mark 0/0 as Red RAG rating
            # These are the positions of the items which need a RAG rating
          elsif self.class.indexes_for_percentage_columns.include?(item_index) && row[item_index + 1] != 0
            OpenStruct.new value: item, rag_rating: rag_rating(item)
          else
            OpenStruct.new value: item
          end
        end
      end
    end

    # This function is only when the report is done via ETL (tasks)
    def report_details(report)
      data_collector = []
      report.job_ids.each do |job_id|
        if Sidekiq.redis { |r| r.exists(job_id).positive? }
          data_collector << Sidekiq.redis { |r| r.get(job_id) }
        end
      end

      if data_collector.count == report.job_ids.count
        report.status = Stats::BaseReport::COMPLETE
        merge_stats(data_collector)
        report.report_data = @stats.stats.to_json
        report.save!
        report.report_data
      end
    end

    def data_size
      CaseSelector.new(case_scope).cases_received_in_period(@period_start, @period_end).size.to_f
    end

    def num_fragments
      @num_fragments ||= (data_size / ROWS_PER_FRAGMENT).ceil
    end

    def superheadings
      [
        ["#{self.class.title} - #{reporting_period}"],
        self.class.report_notes,
        [producer_stamp],
        MONTHLY_PERFORMANCE_SPECIFIC_SUPERHEADINGS.merge(self.class.case_analyzer::COMMON_SUPERHEADINGS).values,
      ]
    end

    def analyse_case(kase)
      analyser = self.class.case_analyzer.new(kase)
      analyser.run
      column_key = analyser.result
      month = construct_year_month(kase.received_date)

      if block_given?
        yield month, column_key
      else
        @stats.record_stats(month, column_key)
        @stats.record_stats(:total, column_key)
      end
    end

    def array_of_month_numbers
      month_columns = []
      month_date = @period_start
      current_month = construct_year_month(@period_start)
      end_month = construct_year_month(@period_end)

      while current_month <= end_month
        month_columns << current_month
        month_date += 1.month
        current_month = construct_year_month(month_date)
      end

      month_columns
    end

    def populate_month_names_callback(stats)
      stats.stats.each do |month_no, result_set|
        result_set[:month] = if month_no == :total
                               "Total"
                             else
                               Date::MONTHNAMES[get_month_from_yearmonth_string(month_no)]
                             end
      end
    end

    def case_scope
      raise "This method should be defined in the child class"
    end

  private

    def get_month_from_yearmonth_string(yearmonth_string)
      yearmonth_string.to_s.last(2).to_i
    end

    def construct_year_month(the_date)
      month_str = sprintf("%02i", the_date.month)
      start_month = "#{the_date.year}#{month_str}"
      start_month.to_i
    end

    def producer_stamp
      "Created at #{Time.zone.today.to_date}"
    end

    def create_background_jobs
      offset = 0
      @job_ids = []
      (1..num_fragments).map do |_i|
        job_id = SecureRandom.uuid
        PerformanceReportJob.perform_later(
          self.class.name,
          job_id,
          @period_start.to_i,
          @period_end.to_i,
          offset,
        )
        @job_ids << job_id
        offset += ROWS_PER_FRAGMENT
      end
      @background_job = true
      @status = Stats::BaseReport::WAITING
    end

    def init_merged_stats
      merged_result = {}
      (array_of_month_numbers + [:total]).each do |row|
        merged_result[row] = {}
      end
      merged_result
    end

    def merge_stats(data_collector)
      merged_stats = init_merged_stats
      data_collector.each do |data|
        data_object = JSON.parse(data, symbolize_names: true)
        data_object.each do |month, stats|
          month_key = month.to_s.to_i.positive? ? month.to_s.to_i : month
          stats.each do |stat_item, value|
            next unless merged_stats.key?(month_key)

            unless merged_stats[month_key].key?(stat_item)
              merged_stats[month_key][stat_item] = 0
            end
            merged_stats[month_key][stat_item] += value
          end
        end
      end
      @stats.stats = merged_stats
      @stats.finalise
    end
  end
end
