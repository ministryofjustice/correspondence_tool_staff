require "cts"

module CTS::Cases
  class Warehouser
    attr_accessor :logger

    def initialize(logger, options = {})
      @logger = logger
      @options = options
    end

    def call
      logger.info Benchmark::CAPTION
      logger.info(Benchmark.measure { @added, @deleted = handle_task })
      logger.info "\n#{@added} cases added to warehouse\n#{@deleted} cases deleted from warehouse\n"
    end

  private

    def handle_task
      case @options[:scope]
      when "all"
        reconcile_cases
      when "case_number"
        if @options[:number].present?
          generate_case_sync_jobs_by_case_number(@options[:number])
        else
          raise "Please provide the number string of a case, please check help"
        end
      when "case_id_range"
        if @options[:start].present? && @options[:end].present?
          generate_case_sync_jobs_by_id_range(@options[:start], @options[:end])
        else
          raise "Please provide the id range of cases, please check help"
        end
      else
        raise "Unrecognised option please check help"
      end
    end

    def reconcile_cases
      Warehouse::CaseReport.reconcile(@options[:size])
    end

    def generate_case_sync_jobs_by_id_range(start_case_id, end_case_id)
      Case::Base.where(id: start_case_id..end_case_id).each do |kase|
        ::Warehouse::CaseSyncJob.perform_later(kase.class.to_s, kase.id)
      end
    end

    def generate_case_sync_jobs_by_case_number(case_number)
      kase = Case::Base.where(number: case_number).first
      if kase.present?
        ::Warehouse::CaseSyncJob.perform_later(kase.class.to_s, kase.id)
      end
    end
  end
end
