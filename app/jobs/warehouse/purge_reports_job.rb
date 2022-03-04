module Warehouse
  class PurgeReportsJob < ApplicationJob

    queue_as :reports

    def perform
      SentryContextProvider.set_context

      # Reports generated, regardless if downloaded or not
      Report.destroy_all
    end
  end
end
