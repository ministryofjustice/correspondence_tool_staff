class AddReferenceToCases < ActiveRecord::Migration[5.0]
  def change
    add_column :cases, :reference, :integer, null: false
  end
end
