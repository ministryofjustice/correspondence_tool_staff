class AddDataRequestAreaToDataRequest < ActiveRecord::Migration[7.1]
  def change
    add_column :data_requests, :data_request_area, :text, null: false, default: ""
  end
end
