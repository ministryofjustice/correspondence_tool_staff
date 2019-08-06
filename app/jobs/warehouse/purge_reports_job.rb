module Warehouse
  class PurgeReportsJob < ApplicationJob

    queue_as :warehouse

    def perform
      RavenContextProvider.set_context

      Report.destroy_all
      # Delete all temp files
      # Clear Redis queues if any
    end
  end
end
