class AddActiveFlagToCaseClosureMetadata < ActiveRecord::Migration[5.0]
  def change
    add_column :case_closure_metadata, :active, :boolean, default: true
  end
end
