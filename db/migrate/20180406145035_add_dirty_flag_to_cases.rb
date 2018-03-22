class AddDirtyFlagToCases < ActiveRecord::Migration[5.0]
  def change
    add_column :cases, :dirty, :boolean, default: false
  end
end
