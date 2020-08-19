class AddCompletedToDataRequest < ActiveRecord::Migration[5.2]
  def change
    add_column :data_requests, :completed, :boolean, default: false, null: false
  end
end
