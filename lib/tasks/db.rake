namespace :db do
  desc "Erase all tables"
  task clear: :environment do
    if is_on_production?
      puts "Cannot run this command on production environment!"
    else
      HostEnv.safe do
        clear_database
      end
    end
  end

  desc "Clear the database, run migrations and basic seeds (not users, teams, roles)"
  task reseed: :environment do
    if is_on_production?
      puts "Cannot run this command on production environment!"
    else
      safeguard_question
      Rake::Task["db:clear"].invoke
      Rake::Task["db:structure_load"].invoke
      Rake::Task["data:migrate"].invoke
      Rake::Task["db:seed:dev:teams"].invoke
      Rake::Task["db:seed:dev:users"].invoke
    end
  end

  task structure_load: :environment do
    if is_on_production?
      puts "Cannot run this command on production environment!"
    else
      structure_file = "#{Rails.root}/db/structure.sql"
      db_connection_url = ENV["DATABASE_URL"] || "postgres://postgres:@localhost/correspondence_platform_development"
      command = "psql #{db_connection_url} < #{structure_file}"
      system command
    end
  end

  def clear_database
    conn = ActiveRecord::Base.connection
    tables = conn.tables
    tables.each do |table|
      puts "Deleting #{table}"
      conn.drop_table(table, force: :cascade)
    end

    enum_types = %w[
      attachment_type
      cases_delivery_methods
      requester_type
      search_query_type
      state
      team_roles
      user_role
    ]
    enum_types.each do |type|
      conn.execute("DROP TYPE IF EXISTS #{type}")
    end
  end

  def is_on_production?
    ENV["ENV"].present? && ENV["ENV"] == "prod"
  end

  def safeguard_question
    if ENV["ENV"].present?
      print "Are you sure to reset the database into initial state: no cases with default users and teams? Y/n "
      input = $stdin.gets.chomp
      exit unless input.start_with?("Y") || input.nil?
    end
  end
end
