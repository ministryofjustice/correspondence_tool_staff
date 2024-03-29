class InitialSeed < ActiveRecord::DataMigration
  def up
    require Rails.root.join("db/seeders/correspondence_type_seeder")
    require Rails.root.join("db/seeders/case_closure_metadata_seeder")
    require Rails.root.join("db/seeders/report_type_seeder")

    CorrespondenceTypeSeeder.new.seed!
    ReportTypeSeeder.new.seed!(verbose: true)
    CaseClosure::MetadataSeeder.seed!(verbose: true)
  end
end
