class AddDeletedToCases < ActiveRecord::Migration[5.0]
  def change
    add_column :cases, :deleted?, :boolean, default: false
    add_index :cases, :deleted?
  end
end
