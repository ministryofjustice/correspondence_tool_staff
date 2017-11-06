class UpdateCaseClosureData < ActiveRecord::Migration[5.0]
  def up
    require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')
    CaseClosure::MetadataSeeder.implement_oct_2017_changes(verbose: false)
  end

  def down
    if Rails.env.production?
      raise ActiveRecord::IrreversibleMigration, "Unable to reverse data migration (CaseClosure::Metadatum)"
    end
  end

end
