class SeedDisclosedLetterTemplates < ActiveRecord::DataMigration
  def up
    # put your code here
    require File.join(Rails.root, "db", "seeders", "letter_template_seeder")
    LetterTemplateSeeder.new.bau_disclosed_letter_seed
  end
end
