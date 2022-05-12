class AddTypeColumnToCases < ActiveRecord::Migration[5.0]
  def change
    add_column :cases, :type, :string, default: 'Case'
  end
end
