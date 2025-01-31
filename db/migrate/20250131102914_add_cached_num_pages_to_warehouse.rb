class AddCachedNumPagesToWarehouse < ActiveRecord::Migration[7.2]
  def change
    add_column :warehouse_case_reports, :cached_num_pages, :integer
  end
end
