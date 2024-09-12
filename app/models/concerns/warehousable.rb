module Warehousable
  extend ActiveSupport::Concern

  included do
    after_commit :warehouse, if: :update_warehouse?
  end

  class_methods do
    attr_accessor :warehousable

    def warehousable_attributes(attributes)
      self.warehousable = attributes
    end
  end

  def update_warehouse?
    self.class.warehousable.nil? ||
      previous_changes.keys.include?(self.class.warehousable)
  end

  # Add any further warehousing operations here, ideally async
  def warehouse
    ::Warehouse::CaseSyncJob.perform_later(self.class.to_s, id)
  end
end
