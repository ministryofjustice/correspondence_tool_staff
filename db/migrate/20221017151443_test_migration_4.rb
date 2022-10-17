class TestMigration4 < ActiveRecord::Migration[6.1]
  def change
    add_column :warehouse_case_reports, :test_field_4, :string
  end
end
