require "cts"

module CTS::Cases
  class Reindex
    attr_accessor :logger

    def initialize(logger, options = {})
      @logger = logger
      @options = options
    end

    def call
      logger.info Benchmark::CAPTION
      logger.info(Benchmark.measure { @count = process_indexes })
      logger.info "\n#{@count} cases reindexed"
    end

  private

    def process_indexes
      if @options[:non_indexed]
        size = @options[:size]
        logger.info "Start to query the cases with size #{size}."
        cases = Case::Base.where("document_tsvector is NULL").limit(size)
        cases.each do |kase|
          SearchIndexUpdaterJob.perform_later(kase.id)
          logger.info("The task of updateing the case with id: #{kase.id} (#{kase.number}) has been triggered")
        end
        cases.count
      else
        logger.info "Start to query all the cases."
        Case::Base.update_all_indexes.count
      end
    end
  end
end
