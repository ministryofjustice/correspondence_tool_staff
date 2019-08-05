module Warehouse
  class PurgeReportsJob < ApplicationJob

    queue_as :warehouse

    def perform
      Report.destroy_all
      # Delete all temp files
      # Clear Redis queues if any
    end
  end
end
