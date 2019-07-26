require 'cts'

module CTS::Cases
  class Warehouser
    attr_accessor :logger

    def initialize(logger, options = {})
      @logger = logger
      @options = options
    end

    def call
      logger.info Benchmark::CAPTION
      logger.info Benchmark.measure { @added, @deleted = Warehouse::CasesReport.reconcile }
      logger.info "\n#{@added} cases added to warehouse\n#{@deleted} cases deleted from warehouse\n"
    end
  end
end
