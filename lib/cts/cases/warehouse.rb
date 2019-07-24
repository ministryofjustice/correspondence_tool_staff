require 'cts'

module CTS::Cases
  class Warehouse
    attr_accessor :logger

    def initialize(logger, options = {})
      @logger = logger
      @options = options
    end

    def call
      logger.info Benchmark::CAPTION
      logger.info Benchmark.measure { @count = Case::Base.update_all_indexes.count }
      logger.info "\n#{@count} cases warehoused"
    end
  end
end
