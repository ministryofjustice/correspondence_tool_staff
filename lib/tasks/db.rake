namespace :db do

  desc 'Erase all tables'
  task :clear => :environment do
    if production_environment?
      raise "Unable to run rake db:clear in #{Rails.env} environment"
    else
      clear_database
    end
  end

  desc 'Clear the database, run migrations and seeds'
  task :reseed => [:clear, 'db:migrate', 'db:seed'] {}

  def clear_database
    conn = ActiveRecord::Base.connection
    tables = conn.tables
    tables.each do |table|
      puts "Deleting #{table}"
      conn.drop_table(table, force: :cascade)
    end

    %w(assignment_type attachment_type requester_type state).each do |type|
      conn.execute("DROP TYPE IF EXISTS #{type}")
    end
  end

  def production_environment?
    ENV['ENV'] == 'prod' || Rails.env.production?
  end

end

