module Warehouse
  class CasesSyncJob < ApplicationJob

    queue_as :warehouse

    def perform(active_record_type, model_id)
      RavenContextProvider.set_context
      record = active_record_type.constantize.find_by(id: model_id)

      if record
        ::Stats::Warehouse::CasesReportSync.new(record)
      else
        Rails.logger.error("CasesSyncJob [FAIL] #{active_record_type}/#{model_id} to sync")
      end
    end

    def self.sync?(record)
      ::Stats::Warehouse::CasesReportSync.syncable?(record).first
    end
  end
end
