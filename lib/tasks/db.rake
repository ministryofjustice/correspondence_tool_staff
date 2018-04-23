namespace :db do

  desc 'Erase all tables'
  task :clear => :environment do
    HostEnv.safe do
      clear_database
    end
  end

  desc 'Clear the database, run migrations and basic seeds (not users, teams, roles)'
  task :reseed => :clear do
    ENV['RESEEDING_DATABASE'] = '1'
    Rake::Task['db:migrate'].invoke
    Rake::Task['db:seed'].invoke
    Rake::Task['db:seed:dev:teams'].invoke
    Rake::Task['db:seed:dev:users'].invoke
  end


  task :anon => :environment do
    Anonymizer.new.run
  end

  def clear_database
    conn = ActiveRecord::Base.connection
    tables = conn.tables
    tables.each do |table|
      puts "Deleting #{table}"
      conn.drop_table(table, force: :cascade)
    end

    enum_types = %w(
      assignment_type
      attachment_type
      requester_type
      state
      user_role
      team_roles
      cases_delivery_methods
      search_query_type
    )
    enum_types.each do |type|
      conn.execute("DROP TYPE IF EXISTS #{type}")
    end
  end

end

