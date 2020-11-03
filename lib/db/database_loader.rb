class DatabaseLoader

  def initialize(env, folder_for_load)
    @env = env
    @db_connection_url = ENV['DATABASE_URL'] || 'postgres://localhost/correspondence_platform_development'
    @folder_for_load = folder_for_load
    raise "This task is not allowed on non-prod environment." unless @env != 'prod'
  end

  def run
    drop_and_recreate_database
    load_database
  end

  private

  def add_role(filename)
    system "sed -e $'1i\\\nCREATE ROLE correspondence_staff;\n' -i .bak #{filename}"
    puts "File #{filename} updated to add CREATE ROLE line - original saved in #{filename}.bak"
    filename
  end

  def drop_and_recreate_database
    ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK'] = '1'
    Rake::Task['db:drop'].invoke
    puts "Database dropped"
    Rake::Task['db:create'].invoke
    puts "Database created"
  end

  def load_database
    puts "#{@folder_for_load}/*.sql"
    Dir.glob("#{@folder_for_load}/*.sql").sort.map do | local_filename |
      result = system "psql #{@db_connection_url} -f #{local_filename}"
      raise "Failed to load #{local_filename} into the database!" unless result == true
    end
  end
end
