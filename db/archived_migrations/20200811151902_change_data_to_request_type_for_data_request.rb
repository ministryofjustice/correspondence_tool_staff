class ChangeDataToRequestTypeForDataRequest < ActiveRecord::Migration[5.2]
  def change
    rename_column :data_requests, :data, :request_type
  end
end
