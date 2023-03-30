class AllowNilDataRequestLocation < ActiveRecord::Migration[6.1]
  def change
    change_column_null :data_requests, :location, true
  end
end
