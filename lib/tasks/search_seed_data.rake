namespace :seed do
  namespace :search do
    desc "Seeds the database ready for testing full text search"
    task data: :environment do
      raise "Cannot run this task on the production environment" if HostEnv.production?

      require File.join(Rails.root, "db", "seeders", "search_test_data_seeder")
      Rake::Task["db:seed:dev:teams"].invoke
      Rake::Task["db:seed:dev:users"].invoke

      SearchTestDataSeeder.new.run
    end
  end
end
