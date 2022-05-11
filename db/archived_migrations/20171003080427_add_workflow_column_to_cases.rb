class AddWorkflowColumnToCases < ActiveRecord::Migration[5.0]
  def change
    add_column :cases, :workflow, :string
  end
end
