class AddLastIndexedAtToCases < ActiveRecord::Migration[8.1]
  def change
    add_column :cases, :last_indexed_at, :datetime, null: true
  end
end
