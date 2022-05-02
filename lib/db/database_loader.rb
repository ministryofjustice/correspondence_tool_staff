require File.join(Rails.root, 'lib', 'db', 'users_settings_for_anonymizer')

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

  def drop_and_recreate_database
    # The following way for resetting the db has no need to stop the app server instances 
    # but after the restoring, you may need to restart the instances in order to clear up the cache.
    result = system "psql #{@db_connection_url} -c \"drop schema public cascade;\""
    raise "Failed to drop the database!" unless result == true
    result = system "psql #{@db_connection_url} -c \"create schema public;;\""
    raise "Failed to recreate public empty schema for this database!" unless result == true
  end

  def load_database
    puts "#{@folder_for_load}/*.sql"
    Dir.glob("#{@folder_for_load}/*.sql").sort.map do | local_filename |
      result = system "psql #{@db_connection_url} -f #{local_filename}"
      raise "Failed to load #{local_filename} into the database!" unless result == true
    end
  end
end
