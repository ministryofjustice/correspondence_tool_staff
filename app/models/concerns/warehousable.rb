module Warehousable
  extend ActiveSupport::Concern

  included do
    class_attribute :warehousable

    after_commit :warehouse, if: :update_warehouse?
  end

  class_methods do
    def warehousable_attributes(*attributes)
      self.warehousable = attributes.map(&:to_s)
    end
  end

  def update_warehouse?
    self.class.warehousable.nil? ||
      previous_changes.keys.intersect?(self.class.warehousable)
  end

  # Add any further warehousing operations here, ideally async
  def warehouse
    ::Warehouse::CaseSyncJob.perform_later(self.class.to_s, id)
  end
end
