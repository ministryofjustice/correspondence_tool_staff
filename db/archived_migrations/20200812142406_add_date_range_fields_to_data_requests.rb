class AddDateRangeFieldsToDataRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :data_requests, :date_from, :date, null: true
    add_column :data_requests, :date_to, :date, null: true
  end
end
