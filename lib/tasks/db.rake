namespace :db do

  desc 'Erase all tables'
  task :clear => :environment do
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

  desc 'Clear the database, run migrations and seeds'
  task :reseed => [:clear, 'db:migrate', 'db:seed'] {}
end