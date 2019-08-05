module Warehouse
  class ClosedCasesSyncJob < ApplicationJob

    queue_as :warehouse

    def perform(active_record_type, model_id)
      record = active_record_type.constantize.find(model_id)
      Warehouse::CasesReport.sync(record)
    end
  end
end
