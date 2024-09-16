module Warehousable
  extend ActiveSupport::Concern

  included do
    after_commit :warehouse, if: :update_warehouse?
  end

  class_methods do
    def warehousable_attributes(*attributes)
      # Use a class variable so it is inherited by all subclasses
      @@warehousable = attributes.map(&:to_s) # rubocop:disable Style/ClassVars
    end
  end

  def update_warehouse?
    @@warehousable.nil? ||
      previous_changes.keys.intersect?(@@warehousable)
  end

  # Add any further warehousing operations here, ideally async
  def warehouse
    ::Warehouse::CaseSyncJob.perform_later(self.class.to_s, id)
  end
end
