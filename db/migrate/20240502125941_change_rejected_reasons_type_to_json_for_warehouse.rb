class ChangeRejectedReasonsTypeToJsonForWarehouse < ActiveRecord::Migration[7.1]
  def up
    remove_column :warehouse_case_reports, :rejected_reasons, :string # rubocop:disable Rails/BulkChangeTable
    add_column :warehouse_case_reports, :rejected_reasons, :json, using: "rejected_reasons::json"
  end

  def down
    change_column :warehouse_case_reports, :rejected_reasons, :string
  end
end
