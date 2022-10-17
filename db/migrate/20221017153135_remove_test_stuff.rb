class RemoveTestStuff < ActiveRecord::Migration[6.1]
  def change
    remove_column :warehouse_case_reports, :test_field, :string
    remove_column :warehouse_case_reports, :test_field_2, :string
    remove_column :warehouse_case_reports, :test_field_3, :string
    remove_column :warehouse_case_reports, :test_field_4, :string
  end
end
