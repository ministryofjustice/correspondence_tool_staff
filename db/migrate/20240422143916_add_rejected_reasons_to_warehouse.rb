class AddRejectedReasonsToWarehouse < ActiveRecord::Migration[7.1]
  def change
    add_column :warehouse_case_reports, :rejected_reasons, :string # rubocop:disable Rails/BulkChangeTable
    add_column :warehouse_case_reports, :other_rejected_reason, :string
  end
end
