class SeedInitialLetterTemplates < ActiveRecord::DataMigration
  def up
    Rake::Task["db:seed:dev:letter_templates"].invoke
  end
end
