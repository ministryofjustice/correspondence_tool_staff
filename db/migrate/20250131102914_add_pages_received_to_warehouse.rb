class AddPagesReceivedToWarehouse < ActiveRecord::Migration[7.2]
  def change
    add_column :warehouse_case_reports, :pages_received, :integer
  end
end
