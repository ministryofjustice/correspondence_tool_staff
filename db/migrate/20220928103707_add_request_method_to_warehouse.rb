class AddRequestMethodToWarehouse < ActiveRecord::Migration[6.1]
  def change
    add_column :warehouse_case_reports, :request_method, :string
  end
end
