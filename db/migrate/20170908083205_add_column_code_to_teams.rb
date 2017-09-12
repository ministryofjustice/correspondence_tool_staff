class AddColumnCodeToTeams < ActiveRecord::Migration[5.0]
  def change
    add_column :teams, :code, :string, default: nil
    add_index :teams, :code, unique: true
  end
end
