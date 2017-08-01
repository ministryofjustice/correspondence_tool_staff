
namespace :db do
  namespace :seed do

    namespace :prod do
      desc 'Seed users, teams, roles for production environemnt'
      task :users => :environment do
        require File.join(Rails.root, 'db', 'seeders', 'user_seeder')
        UserSeeder.new.seed!
      end
    end


    namespace :dev do
      desc 'Seed users, teams, roles for dev environemnt'
      task :users => :environment do
        require File.join(Rails.root, 'db', 'seeders', 'dev_team_seeder')
        DevTeamSeeder.new.seed!

        require File.join(Rails.root, 'db', 'seeders', 'dev_user_seeder')
        DevUserSeeder.new.seed!
      end
    end

  end
end
