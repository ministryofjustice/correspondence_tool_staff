class HyphenWhenNoPrisonNumberLetterTemplate < ActiveRecord::DataMigration
  def up
    # put your code here
    require Rails.root.join("db/seeders/letter_template_seeder")
    LetterTemplateSeeder.new.seed!
  end
end
