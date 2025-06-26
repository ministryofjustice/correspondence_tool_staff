class ChangeCaseOriginallyRejectedToStringTypeForWarehouse < ActiveRecord::Migration[7.1]
  def up
    change_column :warehouse_case_reports, :case_originally_rejected, :string
  end

  def down
    change_column :warehouse_case_reports, :case_originally_rejected, :boolean, using: "case_originally_rejected::boolean"
  end
end
