class AddCaseOriginallyRejectedFlagToWarehouse < ActiveRecord::Migration[7.1]
  def change
    add_column :warehouse_case_reports, :case_originally_rejected, :boolean, default: nil
  end
end
