class AddRolesToUser < ActiveRecord::Migration[5.0]
  def up
    add_column :users, :roles, :string
  end

  def down
    remove_column :users, :roles, :string
  end
end
