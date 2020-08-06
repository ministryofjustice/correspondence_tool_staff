class AddDetailFieldsToDataRequests < ActiveRecord::Migration[5.2]
  def change
    add_column(:data_requests, :date_from, :date)
    add_column(:data_requests, :date_to, :date)
  end
end
