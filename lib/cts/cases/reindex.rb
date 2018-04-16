require 'cts'

module CTS::Cases
  class Reindex
    attr_accessor :logger

    def initialize(logger, options = {})
      @logger = logger
      @options = options
    end

    def call
      logger.info Benchmark::CAPTION
      logger.info Benchmark.measure { @count = Case::Base.update_all_indexes }
    end
  end
end
