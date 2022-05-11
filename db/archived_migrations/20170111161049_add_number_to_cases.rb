class AddNumberToCases < ActiveRecord::Migration[5.0]
  def change
    add_column :cases, :number, :string, null: false
    add_index :cases, :number, unique: true
  end
end
