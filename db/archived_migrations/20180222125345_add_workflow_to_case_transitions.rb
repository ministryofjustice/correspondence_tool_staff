class AddWorkflowToCaseTransitions < ActiveRecord::Migration[5.0]
  def change
    add_column :case_transitions, :to_workflow, :string
  end
end
