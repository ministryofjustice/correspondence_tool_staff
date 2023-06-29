class DefaultWorklfow < ActiveRecord::Migration[5.0]
  def up
    change_column :cases, :workflow, :string, default: "standard"
  end

  def down
    change_column :cases, :workflow, :string, default: nil
  end
end
