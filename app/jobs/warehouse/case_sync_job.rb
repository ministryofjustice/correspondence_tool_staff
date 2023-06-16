module Warehouse
  class CaseSyncJob < ApplicationJob
    queue_as :warehouse

    def perform(active_record_type, model_id)
      SentryContextProvider.set_context
      record = active_record_type.constantize.find_by(id: model_id)

      if record
        ::Stats::Warehouse::CaseReportSync.new(record)
      else
        Rails.logger.error("CaseSyncJob [FAIL] #{active_record_type}/#{model_id} to sync")
      end
    end
  end
end
