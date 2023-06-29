class AddIndexToTeams < ActiveRecord::Migration[5.0]
  def change
    add_index :teams, %i[type name], unique: true
  end
end
