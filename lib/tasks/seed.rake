namespace :db do
  namespace :seed do
    desc "clear database"
    task clear: :environment do
      puts "WARNING: THIS WILL DELETE ALL EXISTING DATA IN THE DATABASE AND REPOPULATE TEAMS AND USERS"
      print "Do you want to continue? "
      x = $stdin.gets.chomp
      exit unless %w[y Y].include?(x)
      begin
        ActiveRecord::Base.connection.execute "DROP TABLE conversations"
      rescue StandardError => e
        puts "#{e.class} trying to drop conversations table"
        puts e.message
        puts "... continuing anyway."
      end
      require Rails.root.join("spec/support/db_housekeeping")
      DbHousekeeping.clean(seed: false)
    end

    desc "seeds live team and user data"
    task prod: ["db:seed:clear", "db:seed:prod:misc", "db:seed:prod:teams", "db:seed:prod:users", "db:seed:prod:letter_templates"] do
    end

    namespace :prod do
      desc "Seed categories and closure metadata"
      task misc: :environment do
        require Rails.root.join("db/seeders/correspondence_type_seeder")
        puts "Seeding Correspondence Types"
        CorrespondenceTypeSeeder.new.seed!
        require Rails.root.join("db/seeders/case_closure_metadata_seeder")
        puts "Seeding Case closure metadata"
        CaseClosure::MetadataSeeder.seed!
      end

      desc "Seed teams for production environment"
      task teams: :environment do
        require Rails.root.join("db/seeders/team_seeder")
        TeamSeeder.new.seed!
      end

      desc "Seed users, teams, roles for production environemnt"
      task users: :environment do
        require Rails.root.join("db/seeders/user_seeder")
        UserSeeder.new.seed!
      end

      desc "Add group emails to teams"
      task group_emails: :environment do
        require Rails.root.join("db/seeders/group_email_seeder")
        GroupEmailSeeder.new.seed!
      end

      desc "Seed letter templates for production environment"
      task letter_templates: :environment do
        require Rails.root.join("db/seeders/letter_template_seeder")
        LetterTemplateSeeder.new.seed!
      end

      desc "Seed correspondence_types for production environments"
      task correspondence_types: :environment do
        require Rails.root.join("db/seeders/correspondence_type_seeder")
        puts "Seeding Correspondence Types"
        CorrespondenceTypeSeeder.new.seed!
      end
    end

    desc "seed development teams and users"
    task dev: %w[db:seed:dev:teams db:seed:dev:users db:seed:dev:letter_templates]

    namespace :dev do
      desc "Seed teams for dev environment"
      task teams: :environment do
        require Rails.root.join("db/seeders/dev_team_seeder")
        DevTeamSeeder.new.seed!
      end

      desc "Seed users, teams, roles for dev environemnt"
      task users: :environment do
        require Rails.root.join("db/seeders/dev_user_seeder")
        DevUserSeeder.new.seed!
      end

      desc "Seed letter templates for dev environment"
      task letter_templates: :environment do
        require Rails.root.join("db/seeders/letter_template_seeder")
        LetterTemplateSeeder.new.seed!
      end

      desc "Seed correspondence_types for development environments"
      task correspondence_types: :environment do
        require Rails.root.join("db/seeders/correspondence_type_seeder")
        puts "Seeding Correspondence Types"
        CorrespondenceTypeSeeder.new.seed!
      end
    end
  end
end
