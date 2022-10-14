class TestMigration < ActiveRecord::Migration[6.1]
  def change
    add_column :warehouse_case_reports, :test_field, :string
  end
end
