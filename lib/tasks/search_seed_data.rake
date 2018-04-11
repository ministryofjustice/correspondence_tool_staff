namespace :seed do
  namespace :search do
    desc 'Seeds the database ready for testing full text search'
    task data: :environment do
      raise "Cannot run this task on the production environment" if HostEnv.prod?

      # Rake::Task['db:reseed'].invoke
      require File.join(Rails.root, 'db', 'seeders', 'search_test_data_seeder')
      SearchTestDataSeeder.new.run

    end
  end
end
