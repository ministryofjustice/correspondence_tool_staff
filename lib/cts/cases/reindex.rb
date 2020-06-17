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
      logger.info Benchmark.measure { @count = process_indexes }
      logger.info "\n#{@count} cases reindexed"
    end

    private 

    def process_indexes
      if @options[:non_indexed]
        logger.info "Start to query the cases with size #{size}."
        puts @options
        size = @options.fetch(:size)
        cases = Case::Base.where("document_tsvector is NULL").limit(size)
      else 
        logger.info "Start to query all the cases."
        cases = Case::Base.all
      end
      logger.info "Start to process the index"
      cases.each do |kase|
        kase.update_index
        if @options[:non_indexed]
          logger.info("id: #{kase.id} (#{kase.number}) has been indexed")
        end
      end
      cases.count
    end
  end
end
