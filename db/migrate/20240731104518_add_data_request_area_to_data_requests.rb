class AddDataRequestAreaToDataRequests < ActiveRecord::Migration[7.1]
  def change
    add_reference :data_requests, :data_request_area, foreign_key: true
  end
end
