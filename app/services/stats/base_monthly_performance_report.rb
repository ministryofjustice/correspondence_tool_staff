module Stats

  ROWS_PER_FRAGMENT = 500 # Arbitrary value, may require experimentation
  
  class BaseMonthlyPerformanceReport < BaseReport

    R005_SPECIFIC_COLUMNS = {
      month:    'Month'
    }.freeze

    R005_SPECIFIC_SUPERHEADINGS = {
      month:     ''
    }.freeze

    INDEXES_FOR_PERCENTAGE_COLUMNS = [1, 7, 13].freeze

    class << self
      def report_format
        BaseReport::XLSX
      end
    end

    def initialize(**options)
      super(**options)
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

    def process(offset, report_job_guid=nil)
      CaseSelector.new(case_scope)
      .cases_received_in_period(@period_start, @period_end)
      .order(:id)
      .limit(ROWS_PER_FRAGMENT)
      .offset(offset)
      .includes(:responded_transitions, :approver_assignments, :assign_responder_transitions) 
      .each { |kase| analyse_case(kase) }
      if !report_job_guid.nil?
        redis = Redis.new
        redis.set(report_job_guid, @stats.stats.to_json)
      end

    end

    def run(*)
      offset = 0 
      if data_size > ROWS_PER_FRAGMENT
        @job_ids = []
        (1..num_fragments).map do |_i|
          job_id = SecureRandom.uuid
          PerformanceReportJob.perform_later(
            self.class.name,
            job_id,
            @period_start.to_i,
            @period_end.to_i, 
            offset
          )
          @job_ids << job_id
          offset += ROWS_PER_FRAGMENT
        end
        @etl = true
        @status = Stats::BaseReport::WAITING
      else
        @etl = false
        @status = Stats::BaseReport::COMPLETE
        process(offset)
        @stats.finalise
      end 
    end

    def to_csv
      csv = @stats.to_csv(row_names_as_first_column: false, superheadings: superheadings)

      csv.map.with_index do |row, row_index|
        row.map.with_index do |item, item_index|
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

    # def required_to_be_job
    #   return false 
    # end

    # This function is only when the report is done via ETL (tasks)
    def report_details(report)
      redis = Redis.new
      data_collector = []
      report.job_ids.each do |job_id|
        if redis.exists(job_id)
          data_collector << redis.get(job_id)
        end
      end
      if data_collector.count == report.job_ids.count
        report.status = Stats::BaseReport::COMPLETE        
        merge_stats(data_collector)
        report.report_data = (@stats.stats).to_json
        report.save!
        report.report_data
      else
        nil
      end
    end

    def data_size
      CaseSelector.new(case_scope).cases_received_in_period(@period_start, @period_end).size.to_f
    end

    def num_fragments
      @_num_fragments ||= 
      begin
        (data_size/ROWS_PER_FRAGMENT).ceil
      end
    end

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

    def case_scope
      raise 'This method should be defined in the child class'
    end
    
    private

    def merge_stats(data_collector)
      merged_stats = {}
      (array_of_month_numbers + [:total]).each do |row|
        merged_stats[row] = {}
      end
      data_collector.each do |data|
        data_object = JSON.parse(data, symbolize_names: true)
        data_object.each do |month, stats|
          month_key = month.to_s.to_i > 0 ? month.to_s.to_i : month
          stats.each do |stat_item, value|
            if !merged_stats[month_key].key?(stat_item)
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
