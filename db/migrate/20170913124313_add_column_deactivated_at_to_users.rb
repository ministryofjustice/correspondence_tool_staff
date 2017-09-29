class AddColumnDeactivatedAtToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :deleted_at, :datetime, default: nil
  end
end
