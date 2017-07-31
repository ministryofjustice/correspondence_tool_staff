
namespace :db do
  namespace :seed do

    desc 'delete all teams and users'
    task :clear => :environment do
      puts "WARNING: THIS WILL DELETE ALL EXISTING USERS AND TEAMS AND RECREATE"
      print "Do you want to continue? "
      x = STDIN.gets.chomp
      exit unless (x == 'y' || x == 'Y')
      TeamsUsersRole.destroy_all
      User.destroy_all
      Team.destroy_all
    end

    desc 'seeds live team and user data'
    task :prod => [ 'db:seed:clear', 'db:seed:prod:teams', 'db:seed:prod:users' ] do
    end

    namespace :prod do

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
    end

    namespace :dev do
      desc 'Seed teams for dev environment'
      task :teams do
        require File.join(Rails.root, 'db', 'seeders', 'dev_team_seeder')
        DevTeamSeeder.new.seed!
      end

      desc 'Seed users, teams, roles for dev environemnt'
      task :users => :environment do

        require File.join(Rails.root, 'db', 'seeders', 'dev_user_seeder')
        DevUserSeeder.new.seed!
      end
    end

  end
end
