class AddOffenderComplaintOutcome < ActiveRecord::DataMigration
  def up
    require File.join(Rails.root, "db", "seeders", "case_closure_metadata_seeder")
    CaseClosure::MetadataSeeder.implement_jan_2021_changes(verbose: false)
  end

  def down
    if Rails.env.production?
      raise ActiveRecord::IrreversibleMigration, "Unable to reverse data migration (CaseClosure::Metadatum)"
    end
  end
end
