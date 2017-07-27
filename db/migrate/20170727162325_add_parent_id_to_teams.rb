class AddParentIdToTeams < ActiveRecord::Migration[5.0]
  def change
    add_column :teams, :parent_id, :integer
    add_index :teams, :parent_id
  end
end
