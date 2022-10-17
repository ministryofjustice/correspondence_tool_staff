class TestMigration2 < ActiveRecord::Migration[6.1]
  def change
    add_column :warehouse_case_reports, :test_field_2, :string
  end
end
