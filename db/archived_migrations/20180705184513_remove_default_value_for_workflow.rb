class RemoveDefaultValueForWorkflow < ActiveRecord::Migration[5.0]
  def up
    change_column :cases, :workflow, :string, default: nil
  end

  def down
    change_column :cases, :workflow, :string, default: 'standard'
  end
end
