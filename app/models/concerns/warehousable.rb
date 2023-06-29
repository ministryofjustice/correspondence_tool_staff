module Warehousable
  extend ActiveSupport::Concern

  included do
    after_commit :warehouse
  end

  # Add any further warehousing operations here, ideally async
  def warehouse
    ::Warehouse::CaseSyncJob.perform_later(self.class.to_s, id)
  end
end
