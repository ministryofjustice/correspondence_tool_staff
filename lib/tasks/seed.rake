
namespace :db do
  namespace :seed do

    desc 'clear database'
    task :clear => :environment do
      puts "WARNING: THIS WILL DELETE ALL EXISTING DATA IN THE DATABASE AND REPOPULATE TEAMS AND USERS"
      print "Do you want to continue? "
      x = STDIN.gets.chomp
      exit unless (x == 'y' || x == 'Y')
      begin
        ActiveRedord::Base.connection.execute 'DROP TABLE conversations'
      rescue => err
        puts "#{err.class} trying to drop conversations table"
        puts err.message
        puts '... continuing anyway.'
      end
      require File.join(Rails.root, 'spec', 'support', 'db_housekeeping')
      DbHousekeeping.clean(seed: false)
    end

    desc 'seeds live team and user data'
    task :prod => [ 'db:seed:clear', 'db:seed:prod:misc', 'db:seed:prod:teams', 'db:seed:prod:users' ] do
    end

    namespace :prod do

      desc 'Seed categories and closure metadata'
      task :misc => :environment do
        require File.join(Rails.root, 'db', 'seeders', 'correspondence_type_seeder')
        puts 'Seeding Correspondence Types'
        CorrespondenceTypeSeeder.new.seed!
        require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')
        puts 'Seeding Case closure metadata'
        CaseClosure::MetadataSeeder.seed!
        require File.join(Rails.root, 'db', 'seeders', 'letter_template_seeder')
        puts 'Seeding Letter Templates'
        LetterTemplateSeeder.new.seed!
      end

      desc 'Seed teams for production environment'
      task :teams => :environment do
        require File.join(Rails.root, 'db', 'seeders', 'team_seeder')
        TeamSeeder.new.seed!
      end


      desc 'Seed users, teams, roles for production environemnt'
      task :users => :environment do
        require File.join(Rails.root, 'db', 'seeders', 'user_seeder')
        UserSeeder.new.seed!
      end

      desc 'Add group emails to teams'
      task :group_emails => :environment do
        require File.join(Rails.root, 'db', 'seeders', 'group_email_seeder')
        GroupEmailSeeder.new.seed!
      end
    end

    desc 'seed development teams and users'
    task dev: %w[db:seed:dev:teams db:seed:dev:users db:seed:dev:letter_templates]

    namespace :dev do
      desc 'Seed teams for dev environment'
      task teams: :environment do
        require File.join(Rails.root, 'db', 'seeders', 'dev_team_seeder')
        DevTeamSeeder.new.seed!
      end

      desc 'Seed users, teams, roles for dev environemnt'
      task users: :environment do

        require File.join(Rails.root, 'db', 'seeders', 'dev_user_seeder')
        DevUserSeeder.new.seed!
      end

      desc 'Seed letter templates for dev environment'
      task letter_templates: :environment do
        require File.join(Rails.root, 'db', 'seeders', 'letter_template_seeder')
        LetterTemplateSeeder.new.seed!
      end
    end

  end
end
