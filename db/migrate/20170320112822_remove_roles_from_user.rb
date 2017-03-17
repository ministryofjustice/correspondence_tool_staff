class RemoveRolesFromUser < ActiveRecord::Migration[5.0]
  def change
    remove_column :users, :roles, :string
  end
end
