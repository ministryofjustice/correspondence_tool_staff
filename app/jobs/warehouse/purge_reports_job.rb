module Warehouse
  class PurgeReportsJob < ApplicationJob

    queue_as :warehouse

    def perform
      Report.destroy_all
    end
  end
end
