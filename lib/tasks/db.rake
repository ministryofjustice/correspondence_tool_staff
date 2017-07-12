namespace :db do

  desc 'Erase all tables'
  task :clear => :environment do
    require File.join(Rails.root, 'lib', 'rake_task_helpers', 'host_env')
    HostEnv.safe do
      clear_database
    end
  end

  desc 'Clear the database, run migrations and basic seeds (not users, teams, roles)'
  task :reseed => [:clear, 'db:migrate', 'db:seed', 'db:seed:dev:users'] {}

  def clear_database
    conn = ActiveRecord::Base.connection
    tables = conn.tables
    tables.each do |table|
      puts "Deleting #{table}"
      conn.drop_table(table, force: :cascade)
    end

    enum_types = %w(assignment_type attachment_type requester_type state user_role team_roles cases_delivery_methods)
    enum_types.each do |type|
      conn.execute("DROP TYPE IF EXISTS #{type}")
    end
  end

end

