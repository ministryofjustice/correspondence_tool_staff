class AddOutcomeApprovalFlagsForComplaintType < ActiveRecord::DataMigration
  def up
    require Rails.root.join("db/seeders/case_closure_metadata_seeder")
    CaseClosure::MetadataSeeder.implement_feb_2021_changes(verbose: false)
  end

  def down
    if Rails.env.production?
      raise ActiveRecord::IrreversibleMigration, "Unable to reverse data migration (CaseClosure::Metadatum)"
    end
  end
end
