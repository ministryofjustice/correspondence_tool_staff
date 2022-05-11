class AddRequiresExemptionToCaseClosureMetadata < ActiveRecord::Migration[5.0]

  def up
    add_column :case_closure_metadata, :requires_exemption, :boolean, default: false
    execute "UPDATE case_closure_metadata SET requires_exemption = true WHERE name = 'Expemption applied'"
  end

  def down
    remove_column :case_closure_metadata, :requires_exemption
  end
end
