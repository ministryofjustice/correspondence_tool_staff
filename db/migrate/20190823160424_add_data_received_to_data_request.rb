class AddDataReceivedToDataRequest < ActiveRecord::Migration[5.0]
  def change
    add_column :data_requests, :date_received, :date, null: true
    add_column :data_requests, :num_pages, :integer, default: 0, null: false
  end
end
