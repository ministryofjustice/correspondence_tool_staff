class AddRejectedToWarehouse < ActiveRecord::Migration[6.1]
  def change
    add_column :warehouse_case_reports, :rejected, :string, default: "No"
  end
end
