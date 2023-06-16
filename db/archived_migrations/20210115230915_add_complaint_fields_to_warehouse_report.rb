class AddComplaintFieldsToWarehouseReport < ActiveRecord::Migration[5.2]
  def change
    add_column :warehouse_case_reports, :complaint_subtype, :string
    add_column :warehouse_case_reports, :priority, :string
    add_column :warehouse_case_reports, :total_cost, :decimal, precision: 10, scale: 2
    add_column :warehouse_case_reports, :settlement_cost, :decimal, precision: 10, scale: 2
  end
end
