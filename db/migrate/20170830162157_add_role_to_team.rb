class AddRoleToTeam < ActiveRecord::Migration[5.0]
  def change
    add_column :teams, :role, :string, default: nil
  end
end
