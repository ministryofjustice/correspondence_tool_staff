class AddApprovedAtToAssignment < ActiveRecord::Migration[5.0]
  def change
    add_column :assignments, :approved, :boolean, default: false
  end
end
